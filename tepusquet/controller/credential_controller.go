package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/model"
	"tepusquet/service"
)

func GetCredentialForUser(c *gin.Context) {
	result := service.GetCredentialForUser(c.Param("userID"))
	if result.UserID == "" {
		c.Status(http.StatusNotFound)
		return
	}
	c.JSON(http.StatusOK, result)
}

func SetCredentialForUser(c *gin.Context) {
	var input model.UserCredential
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	// Set the user id to ensure that the user can only set their own credentials
	input.UserID = c.Param("userID")
	if err := service.SetCredentialForUser(input); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Credentials encrypted and stored"})
}
