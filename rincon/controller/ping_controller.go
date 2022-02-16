package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/config"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Rincon v" + config.Version + " is online!"})
}