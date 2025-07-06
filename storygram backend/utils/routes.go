package utils

import (
	"context"
	"database/sql"
	"errors"
	db "main/db/sqlc"
	"main/events"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

func RegisterRoutes(server *gin.Engine) {
	authenticated := server.Group("/")
	authenticated.Use(Authenticate)
	server.GET("/GetAuthors", events.GetAllUsersHandler)
	server.POST("/createauthor", events.CreateUserHandler)
	server.GET("/GetAuthor/:id", events.GetUserByIDHandler)
	server.DELETE("/deleteauthor/:id", events.DeleteUserHandler)
	server.PATCH("/updateauthor/:id", events.UpdateUserHandler)

	server.GET("/GetCollaborators/:id", events.GetCollaboratorByIDHandler)
	server.POST("/createcollaborator", events.CreateCollaboratorHandler)
	server.DELETE("/deletecollaborator", events.DeleteCollaboratorHandler)
	server.GET("/GetCollaboratorByStory/:story_id", events.ListCollaboratorsByStoryHandler)

	server.POST("/signup", SignUp)
	server.POST("/login", Login)

	server.POST("/createstories", events.CreateStoryHandler)
	server.GET("/GetStories/:id", events.GetStoryByIDHandler)
	server.GET("/GetAllStories", events.ListStoriesHandler)
	server.DELETE("/deleteStory/:id", events.DeleteStoryHandler)
	server.PATCH("/updateStory/:id", events.UpdateStoryHandler)
	server.GET("/GetStoriesByUser/:user_id", events.ListStoriesByUserHandler)

	server.POST("/createchapter", events.CreateChapterHandler)
	server.GET("/getchapterbyid/:id", events.GetChapterByIDHandler)
	server.GET("/getchapterbystory/:story_id", events.ListChaptersByStoryHandler)
	server.PATCH("/updatechapter/:id", events.UpdateChapterHandler)
	server.DELETE("/deletechapter/:id", events.DeleteChapterHandler)

}

const Secretkey = "totallsecretkeylol1"

type User struct {
	ID       int64  `json:"id" binding:"-"`
	Name     string `json:"name" binding:"-"`
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (u *User) Validate(ctx *gin.Context) error {
	queries, exists := ctx.MustGet("queries").(*db.Queries)
	if !exists {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection not found"})
		return errors.New("database connection not found")
	}

	user, err := queries.GetUserByEmail(context.Background(), u.Email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New("email not found")
		}
		return err
	}

	id, err := strconv.ParseInt(strconv.FormatInt(user.ID, 10), 10, 64)
	if err != nil {
		return errors.New("invalid user ID format")
	}
	u.ID = id
	return nil
}

func SignUp(ctx *gin.Context) {
	queries := ctx.MustGet("queries").(*db.Queries)

	var req struct {
		Name         string `json:"name" binding:"required"`
		Bio          string `json:"bio"`
		Email        string `json:"email" binding:"required,email"`
		Password     string `json:"password" binding:"required,min=6"`
		ProfileImage string `json:"profile_image"`
		Location     string `json:"location"`
		Website      string `json:"website"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input", "details": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password", "details": err.Error()})
		return
	}

	user, err := queries.CreateUser(ctx, db.CreateUserParams{
		Name:         req.Name,
		Bio:          req.Bio,
		Email:        req.Email,
		Password:     string(hashedPassword),
		ProfileImage: req.ProfileImage,
		Location:     req.Location,
		Website:      req.Website,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message": "Signup successful",
		"user":    user,
	})
}

func Login(ctx *gin.Context) {
	var user User

	if err := ctx.ShouldBindJSON(&user); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input", "message": err.Error()})
		return
	}

	queries := ctx.MustGet("queries").(*db.Queries)
	dbUser, err := queries.GetUserByEmail(ctx, user.Email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(dbUser.Password), []byte(user.Password))
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	token, err := Generatetoken(user.Email, dbUser.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
	})
}

func Generatetoken(email string, userid int64) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"Email":  email,
		"userid": userid,
		"exp":    time.Now().Add(time.Hour * 20).Unix(),
	})
	return token.SignedString([]byte(Secretkey))
}

func Authenticate(context *gin.Context) {
	token := context.Request.Header.Get("Authorization")
	if token == "" {
		context.AbortWithStatus(http.StatusNonAuthoritativeInfo)
		return
	}
	err, userid := VerifyToken(token)
	if err != nil {
		context.AbortWithStatus(http.StatusBadRequest)
		return
	}
	context.Set("userid", userid)
	context.Next()

}

func VerifyToken(token string) (error, int64) {
	tokenparsed, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		_, ok := token.Method.(*jwt.SigningMethodHMAC)
		if !ok {
			return nil, errors.New("Wrong token")
		}
		return []byte(Secretkey), nil
	})
	if err != nil {
		return errors.New("couldn't parse"), 0
	}
	validornot := tokenparsed.Valid
	if !validornot {
		return errors.New("the token is not valid or just expired"), 0
	}
	claims, ok := tokenparsed.Claims.(jwt.MapClaims)
	if !ok {
		return errors.New("Invalid Claims"), 0
	}
	useridRaw, exists := claims["userid"]
	if !exists {
		return errors.New("userid not found in claims"), 0
	}
	var Userid int64
	switch v := useridRaw.(type) {
	case float64:
		Userid = int64(v)
	case int64:
		Userid = v
	default:
		return errors.New("unexpected type for userid in claims"), 0
	}

	return nil, Userid
}
