package controller

import (
	"arguello/config"
	"github.com/gin-gonic/gin"
	"net/http"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Arguello v" + config.Version + " is online!"})
}
