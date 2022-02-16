package controller

import "github.com/gin-gonic/gin"

func InitializeRoutes(router *gin.Engine)  {
	router.GET("/rincon/ping", Ping)
	router.GET("/status/:name", GetService)
	router.POST("/service", CreateService)
}