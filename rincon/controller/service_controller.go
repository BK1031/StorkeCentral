package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/config"
	"rincon/model"
	"rincon/service"
	"strconv"
	"time"
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
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, input)
}

func RegisterSelf() {
	// Register service with registry
	var s model.Service
	s.Name = "Rincon"
	s.Version = config.Version
	s.URL = "http://localhost:" + config.Port
	s.Port, _ = strconv.Atoi(config.Port)
	s.StatusEmail = config.StatusEmail
	s.CreatedAt = time.Now()
	service.CreateService(s)
	// Register routes with service
	service.CreateRoute(model.Route{
		Route:       "/rincon",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/status",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/services",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
	service.CreateRoute(model.Route{
		Route:       "/routes",
		ServiceName: "Rincon",
		CreatedAt:   time.Now(),
	})
}