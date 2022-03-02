package controller

import (
	"github.com/gin-gonic/gin"
	"math/rand"
	"net/http"
	"rincon/model"
	"rincon/service"
	"strings"
)

func InitializeRoutes(router *gin.Engine)  {
	router.GET("/rincon/ping", Ping)
	router.GET("/services", GetAllServices)
	router.GET("/services/:name", GetService)
	router.GET("/services/:name/routes", GetRoutesForService)
	router.POST("/services", CreateService)
	router.GET("/status", GetAllServiceStatus)
	router.GET("/status/:name", GetServiceStatus)
	router.GET("/routes", GetAllRoutes)
	router.GET("/routes/:route", GetRoute)
	router.POST("/routes", CreateRoute)
	router.DELETE("/routes/:route", RemoveRoute)
	router.GET("/routes/match/:route/*a", MatchRoute)
}

func MatchRoute(c *gin.Context) {
	var routeUrl = strings.Split(c.Request.URL.Path, "/routes/match")[1]
	print(routeUrl)
	allRoutes := service.GetAllRoutes()
	for i := 0; i < len(allRoutes); i++ {
		if strings.HasPrefix(routeUrl, allRoutes[i].Route) {
			matchedServices := service.GetServiceByName(allRoutes[i].ServiceName)
			if len(matchedServices) == 0 {
				// No services found to handle route
				service.RemoveRoute(allRoutes[i])
				c.JSON(http.StatusNotFound, gin.H{"message": "No service found to handle: " + routeUrl})
				return
			} else {
				// Select a service instance from list
				c.JSON(http.StatusOK, matchedServices[rand.Intn(len(matchedServices))])
				return
			}
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"message": "No service found to handle: " + routeUrl})
	return
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