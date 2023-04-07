package controller

import (
	"montecito/config"
	"net/http"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Montecito v" + config.Version + " is online!"})
}
