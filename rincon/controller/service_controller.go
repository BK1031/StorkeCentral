package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/model"
	"rincon/service"
)

func GetService(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": service.GetServiceByName(c.Param("name"))})
}

func CreateService(c *gin.Context) {
	var input model.Service
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateService(input); err != nil {
		c.JSON(http.StatusBadRequest, err)
	}
	c.JSON(http.StatusOK, input)
}