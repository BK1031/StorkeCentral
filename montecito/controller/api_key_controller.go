package controller

import (
	"github.com/gin-gonic/gin"
	"montecito/model"
	"montecito/service"
	"net/http"
)

func GetAllAPIKeys(c *gin.Context) {
	service.GetAllAPIKeys()
	c.JSON(http.StatusOK, gin.H{"message": "API Keys have been retrieved successfully"})
}

func CreateAPIKey(c *gin.Context) {
	var input model.APIKey
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateAPIKey(input); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "API Key has been created successfully"})
}
