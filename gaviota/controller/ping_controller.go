package controller

import (
	"gaviota/config"
	"github.com/gin-gonic/gin"
	"net/http"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Gaviota v" + config.Version + " is online!"})
}
