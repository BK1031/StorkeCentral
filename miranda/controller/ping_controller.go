package controller

import (
	"miranda/config"
	"net/http"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Miranda v" + config.Version + " is online!"})
}
