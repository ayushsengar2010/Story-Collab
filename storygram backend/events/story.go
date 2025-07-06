package events

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	db "main/db/sqlc"

	"github.com/gin-gonic/gin"
)

func ListStoriesByUserHandler(ctx *gin.Context) {
	userIDStr := ctx.Param("user_id")
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	stories, err := queries.ListStoriesByUserID(ctx, userID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stories"})
		return
	}

	ctx.JSON(http.StatusOK, stories)
}

func GetQueries(c *gin.Context) (*db.Queries, error) {
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

type StoryRequest struct {
	ID            int64     `json:"id" binding:"required"`
	Title         string    `json:"title" binding:"required"`
	Description   string    `json:"description"`
	CoverImage    string    `json:"cover_image"`
	UserID        int64     `json:"user_id" binding:"required"`
	Likes         int64     `json:"likes"`
	Views         int64     `json:"views"`
	PublishedDate time.Time `json:"published_date"`
	LastEdited    time.Time `json:"last_edited"`
	StoryType     string    `json:"story_type"`
	Status        string    `json:"status" binding:"required"`
	Genres        []string  `json:"genres"`
}

func CreateStoryHandler(ctx *gin.Context) {
	var req StoryRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid input",
			"details": err.Error(),
		})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	story, err := queries.CreateStory(ctx, db.CreateStoryParams{
		ID:            req.ID,
		Title:         req.Title,
		Description:   req.Description,
		CoverImage:    req.CoverImage,
		UserID:        req.UserID,
		Likes:         req.Likes,
		Views:         req.Views,
		PublishedDate: req.PublishedDate,
		LastEdited:    req.LastEdited,
		StoryType:     req.StoryType,
		Status:        db.StoryStatus(req.Status),
		Genres:        req.Genres,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create story", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, story)
}

func ListStoriesHandler(ctx *gin.Context) {
	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	stories, err := queries.ListStories(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stories"})
		return
	}

	ctx.JSON(http.StatusOK, stories)
}

func GetStoryByIDHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid story ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	story, err := queries.GetStoryByID(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Story not found"})
		return
	}

	ctx.JSON(http.StatusOK, story)
}

func UpdateStoryHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid story ID"})
		return
	}

	var req StoryRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	story, err := queries.UpdateStory(ctx, db.UpdateStoryParams{
		ID:            id,
		Title:         req.Title,
		Description:   req.Description,
		CoverImage:    req.CoverImage,
		UserID:        req.UserID,
		Likes:         req.Likes,
		Views:         req.Views,
		PublishedDate: req.PublishedDate,
		LastEdited:    req.LastEdited,
		StoryType:     req.StoryType,
		Status:        db.StoryStatus(req.Status),
		Genres:        req.Genres,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update story"})
		return
	}

	ctx.JSON(http.StatusOK, story)
}

func DeleteStoryHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid story ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := queries.DeleteStory(ctx, id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete story"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Story deleted"})
}
