package main

import (
	"github.com/gin-gonic/gin"
	"rincon/config"
	"rincon/controller"
	"rincon/service"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	r.Use(service.JaegerPropogator())
	return r
}

func main() {
	router = setupRouter()
	service.InitializeDB()
	service.SetupGomailClient()
	service.ConnectDiscord()
	controller.InitializeRoutes(router)
	controller.RegisterSelf()
	service.InitializeJaeger()
	if config.Env == "PROD" {
		controller.RegisterStatusCronJob()
	}
	router.Run(":" + config.Port)
}
