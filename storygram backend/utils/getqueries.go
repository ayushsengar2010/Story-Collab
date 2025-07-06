package utils

import (
	"errors"
	db "main/db/sqlc"

	"github.com/gin-gonic/gin"
)

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
