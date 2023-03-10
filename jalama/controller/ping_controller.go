package controller

import (
	"jalama/config"
	"net/http"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Jalama v" + config.Version + " is online!"})
}
