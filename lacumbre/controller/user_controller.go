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

func GetUserByID(c *gin.Context) {
	result := service.GetUserByID(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateUser(c *gin.Context) {
	result := service.GetAllUsers()
	c.JSON(http.StatusOK, result)
}