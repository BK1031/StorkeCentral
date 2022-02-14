package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/config"
)

func setupRouter() *gin.Engine {
	r := gin.Default()
	r.GET("rincon/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "Rincon v" + config.Version + " is online!"})
	})
	return r
}

func main() {
	r := setupRouter()
	r.Run(":" + config.Port)
}
