package events

import (
	"net/http"
	"strconv"

	db "main/db/sqlc"

	"github.com/gin-gonic/gin"
)

type CollaboratorRequest struct {
	StoryID int64  `json:"story_id" validate:"required"`
	Email   string `json:"email" validate:"required,email"`
}

func CreateCollaboratorHandler(ctx *gin.Context) {
	var req CollaboratorRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input", "details": err.Error()})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	user, err := queries.GetUserByEmail(ctx, req.Email)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "User not found with provided email"})
		return
	}

	err = queries.AddCollaborator(ctx, db.AddCollaboratorParams{
		StoryID: req.StoryID,
		UserID:  user.ID,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create collaborator", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Collaborator added successfully"})
}

func GetCollaboratorByIDHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collaborator ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	collab, err := queries.GetCollaborator(ctx, db.GetCollaboratorParams{
		StoryID: id,
		UserID:  id,
	})
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Collaborator not found"})
		return
	}

	ctx.JSON(http.StatusOK, collab)
}

func ListCollaboratorsByStoryHandler(ctx *gin.Context) {
	storyID, err := strconv.ParseInt(ctx.Param("story_id"), 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid story ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	collabs, err := queries.ListCollaboratorsByStory(ctx, storyID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch collaborators"})
		return
	}

	ctx.JSON(http.StatusOK, collabs)
}

func DeleteCollaboratorHandler(ctx *gin.Context) {
	var req struct {
		StoryID int64 `json:"story_id" validate:"required"`
		UserID  int64 `json:"user_id" validate:"required"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input", "details": err.Error()})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	err = queries.RemoveCollaborator(ctx, db.RemoveCollaboratorParams{
		StoryID: req.StoryID,
		UserID:  req.UserID,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete collaborator", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Collaborator deleted successfully"})
}
