package events

import (
	"net/http"
	"strconv"

	db "main/db/sqlc"

	"github.com/gin-gonic/gin"
)

type ChapterRequest struct {
	StoryID       int    `json:"story_id" validate:"required"`
	Title         string `json:"title" validate:"required"`
	Content       string `json:"content"`
	ChapterNumber int    `json:"chapter_number" validate:"required"`
	IsComplete    bool   `json:"is_complete"`
}

func CreateChapterHandler(ctx *gin.Context) {
	var req ChapterRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input", "details": err.Error()})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	chapter, err := queries.CreateChapter(ctx, db.CreateChapterParams{
		StoryID:       int64(req.StoryID),
		Title:         req.Title,
		Content:       req.Content,
		ChapterNumber: int64(req.ChapterNumber),
		IsComplete:    req.IsComplete,
		Column7:       nil,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chapter", "details": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, chapter)
}

func GetChapterByIDHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chapter ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	chapter, err := queries.GetChapterByID(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Chapter not found"})
		return
	}

	ctx.JSON(http.StatusOK, chapter)
}

func ListChaptersByStoryHandler(ctx *gin.Context) {
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

	chapters, err := queries.ListChaptersByStory(ctx, storyID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch chapters"})
		return
	}

	ctx.JSON(http.StatusOK, chapters)
}

func UpdateChapterHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chapter ID"})
		return
	}

	var req ChapterRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	chapter, err := queries.UpdateChapter(ctx, db.UpdateChapterParams{
		ID:         id,
		Title:      req.Title,
		Content:    req.Content,
		IsComplete: req.IsComplete,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update chapter"})
		return
	}

	ctx.JSON(http.StatusOK, chapter)
}

func DeleteChapterHandler(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chapter ID"})
		return
	}

	queries, err := GetQueries(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if _, err := queries.DeleteChapter(ctx, id); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete chapter"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Chapter deleted"})
}
