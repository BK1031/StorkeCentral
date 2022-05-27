package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"lacumbre/model"
	"lacumbre/service"
	"net/http"
)

func GetUserLogins(c *gin.Context) {
	result := service.GetLoginsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateUserLogin(c *gin.Context) {
	var input model.Login
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if service.GetUserByID(input.UserID).ID != "" {
		println("New user login recorded")
		input.ID = uuid.New().String()
		if err := service.CreateLogin(input); err != nil {
			c.JSON(http.StatusInternalServerError, err)
			return
		}
		c.JSON(http.StatusOK, service.GetLoginByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Failed to find requested user!"})
	}
}
