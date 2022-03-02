package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/model"
	"rincon/service"
)

func InitializeRoutes(router *gin.Engine)  {
	router.GET("/rincon/ping", Ping)
	router.GET("/services", GetAllServices)
	router.GET("/services/:name", GetService)
	router.GET("/services/:name/routes", GetRoutesForService)
	router.POST("/services", CreateService)
	router.GET("/status", GetAllServiceStatus)
	router.GET("/status/:name", GetServiceStatus)
	router.GET("/routes/match/:route", MatchRoute)
	router.GET("/routes", GetAllRoutes)
	router.GET("/routes/:route", GetRoute)
	router.POST("/routes", CreateRoute)
	router.DELETE("/routes/:route", RemoveRoute)
}

func MatchRoute(c *gin.Context) {

}

func GetAllRoutes(c *gin.Context) {
	result := service.GetAllRoutes()
	c.JSON(http.StatusOK, result)
}

func GetRoute(c *gin.Context) {
	var r = c.Param("route")
	result := service.GetRouteByID(r)
	if result.Route != r {
		c.JSON(http.StatusNotFound, gin.H{"message": "No route registered for " + r})
		return
	}
	c.JSON(http.StatusOK, result)
}

func GetRoutesForService(c *gin.Context) {
	result := service.GetRouteByService(c.Param("name"))
	c.JSON(http.StatusOK, result)
}

func CreateRoute(c *gin.Context) {
	var input model.Route
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateRoute(input); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, input)
}

func RemoveRoute(c *gin.Context) {
	var r = c.Param("route")
	result := service.GetRouteByID(r)
	if result.Route != r {
		c.JSON(http.StatusNotFound, gin.H{"message": "No route registered for " + r})
		return
	}
	service.RemoveRoute(result)
	c.JSON(http.StatusOK, gin.H{"message": "Successfully removed route " + r})
}