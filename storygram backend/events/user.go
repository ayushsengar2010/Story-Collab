package events

import (
	"errors"
	"net/http"
	"strconv"

	db "main/db/sqlc"

	"github.com/gin-gonic/gin"
)

func getQueries(c *gin.Context) (*db.Queries, error) {
	val, exists := c.Get("queries")
	if !exists {
		return nil, errors.New("queries not found in context")
	}

	queries, ok := val.(*db.Queries)
	if !ok {
		return nil, errors.New("invalid queries type in context")
	}

	return queries, nil
}

type UserRequest struct {
	ID           int64  `json:"id" binding:"required"`
	Name         string `json:"name" binding:"required"`
	Bio          string `json:"bio"`
	ProfileImage string `json:"profile_image" binding:"-"`
	Location     string `json:"location"`
	Website      string `json:"website" binding:"-"`
	Followers    int64  `json:"followers"`
	Following    int64  `json:"following"`
	StoriesCount int64  `json:"stories_count"`
	IsVerified   bool   `json:"is_verified"`
}

func CreateUserHandler(ctx *gin.Context) {
	var req UserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	queries, err := getQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	user, err := queries.CreateUser(ctx, db.CreateUserParams{
		Name:         req.Name,
		Bio:          req.Bio,
		ProfileImage: req.ProfileImage,
		Location:     req.Location,
		Website:      req.Website,
		Followers:    req.Followers,
		Following:    req.Following,
		StoriesCount: req.StoriesCount,
		IsVerified:   req.IsVerified,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, user)
}

func GetAllUsersHandler(ctx *gin.Context) {
	queries, err := getQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	users, err := queries.ListUsers(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, users)
}

func GetUserByIDHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	queries, err := getQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	user, err := queries.GetUserByID(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	ctx.JSON(http.StatusOK, user)
}

func UpdateUserHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var req UserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	queries, err := getQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	user, err := queries.UpdateUser(ctx, db.UpdateUserParams{
		ID:           id,
		Name:         req.Name,
		Bio:          req.Bio,
		ProfileImage: req.ProfileImage,
		Location:     req.Location,
		Website:      req.Website,
		Followers:    req.Followers,
		Following:    req.Following,
		StoriesCount: req.StoriesCount,
		IsVerified:   req.IsVerified,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, user)
}

func DeleteUserHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	queries, err := getQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := queries.DeleteUser(ctx, id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}
