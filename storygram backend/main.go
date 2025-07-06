package main

import (
	"context"
	"log"

	db "main/db/sqlc"
	"main/utils"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func InjectQueries(queries *db.Queries) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("queries", queries)
		c.Next()
	}
}

func main() {
	mainDBURL := "postgresql://root:Nikhil%40123k@18.232.150.66:5432/project3postgresql1?sslmode=disable"
	mainConn, err := pgxpool.New(context.Background(), mainDBURL)
	if err != nil {
		log.Fatal("Cannot connect to main database:", err)
	}
	defer mainConn.Close()
	mainQueries := db.New(mainConn)

	router := gin.Default()

	router.Use(InjectQueries(mainQueries))

	router.Use(func(ctx *gin.Context) {
		ctx.Set("queries", mainQueries)
		ctx.Next()
	})

	utils.RegisterRoutes(router)

	log.Fatal(router.Run(":8080"))
}
