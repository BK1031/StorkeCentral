package controller

import "github.com/gin-gonic/gin"

func InitializeRoutes(router *gin.Engine)  {
	router.GET("/rincon/ping", Ping)
	router.GET("/services", GetAllServices)
	router.GET("/services/:name", GetService)
	router.POST("/services", CreateService)
	router.GET("/status/:name", GetServiceStatus)
}