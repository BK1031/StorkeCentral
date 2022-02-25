package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/model"
	"rincon/service"
	"strconv"
)

func GetAllServices(c *gin.Context) {
	result := service.GetAllServices()
	c.JSON(http.StatusOK, result)
}

func GetService(c *gin.Context) {
	if i, err := strconv.Atoi(c.Param("name")); err == nil {
		// integer id passed
		result := service.GetServiceByID(i)
		if result.ID != i {
			c.JSON(http.StatusNotFound, gin.H{"message": "No service with id " + strconv.Itoa(i) + " found"})
			return

		}
		c.JSON(http.StatusOK, result)
		return
	}
	// string name passed
	result := service.GetServiceByName(c.Param("name"))
	c.JSON(http.StatusOK, result)
}

func CreateService(c *gin.Context) {
	var input model.Service
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateService(input); err != nil {
		c.JSON(http.StatusBadRequest, err)
		return
	}
	c.JSON(http.StatusOK, input)
}