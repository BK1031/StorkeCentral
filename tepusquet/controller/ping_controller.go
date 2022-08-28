package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/config"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Tepusquet v" + config.Version + " is online!"})
}
