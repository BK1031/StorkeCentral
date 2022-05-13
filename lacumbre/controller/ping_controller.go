package controller

import (
	"github.com/gin-gonic/gin"
	"lacumbre/config"
	"net/http"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Lacumbre v" + config.Version + " is online!"})
}