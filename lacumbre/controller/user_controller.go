package controller

import (
	"github.com/gin-gonic/gin"
	"lacumbre/service"
	"net/http"
)

func GetAllUsers(c *gin.Context) {
	result := service.GetAllUsers()
	c.JSON(http.StatusOK, result)
}

