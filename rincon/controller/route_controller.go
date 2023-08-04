package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"math/rand"
	"net/http"
	"rincon/config"
	"rincon/model"
	"rincon/service"
	"strings"
)

func InitializeRoutes(router *gin.Engine) {
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
	router.GET("/routes/match/:route", MatchRoute)
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		println("GATEWAY REQUEST ID: " + c.GetHeader("Request-ID"))
		c.Next()
	}
}

func MatchRoute(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "MatchRoute", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var routeUrl = "/" + strings.ReplaceAll(c.Param("route"), "%2F", "/")
	println(routeUrl)
	allRoutes := service.GetAllRoutes()
	for i := 0; i < len(allRoutes); i++ {
		if strings.HasPrefix(routeUrl, allRoutes[i].Route) {
			matchedServices := service.GetServiceByName(allRoutes[i].ServiceName)
			if len(matchedServices) == 0 {
				// No services found to handle route
				service.RemoveRoute(allRoutes[i])
				c.JSON(http.StatusNotFound, gin.H{"message": "No service found to handle: " + routeUrl})
				service.Discord.ChannelMessageSend(config.DiscordChannel, "Failed to find active service `"+allRoutes[i].ServiceName+"` for route `"+allRoutes[i].Route+"`")
				return
			} else {
				// Select a service instance from list
				c.JSON(http.StatusOK, matchedServices[rand.Intn(len(matchedServices))])
				service.Discord.ChannelMessageSend(config.DiscordChannel, "Successfully mapped active service `"+allRoutes[i].ServiceName+"` to route `"+allRoutes[i].Route+"` for route `"+routeUrl+"`")
				return
			}
		}
	}
	c.JSON(http.StatusNotFound, gin.H{"message": "No service found to handle: " + routeUrl})
	service.Discord.ChannelMessageSend(config.DiscordChannel, "Failed to find mapped route for route `"+routeUrl+"`")
	return
}

func GetAllRoutes(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetAllRoutes", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllRoutes()
	c.JSON(http.StatusOK, result)
}

func GetRoute(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetRoute", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var r = "/" + strings.ReplaceAll(c.Param("route"), "%2F", "/")
	result := service.GetRouteByID(r)
	if result.Route != r {
		c.JSON(http.StatusNotFound, gin.H{"message": "No route registered for " + r})
		return
	}
	c.JSON(http.StatusOK, result)
}

func GetRoutesForService(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetRoutesForService", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetRouteByService(c.Param("name"))
	c.JSON(http.StatusOK, result)
}

func CreateRoute(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "CreateRoute", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

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
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "RemoveRoute", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var r = "/" + strings.ReplaceAll(c.Param("route"), "%2F", "/")
	result := service.GetRouteByID(r)
	if result.Route != r {
		c.JSON(http.StatusNotFound, gin.H{"message": "No route registered for " + r})
		return
	}
	service.RemoveRoute(result)
	c.JSON(http.StatusOK, gin.H{"message": "Successfully removed route " + r})
}
