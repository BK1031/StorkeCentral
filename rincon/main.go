package main

import (
	"github.com/gin-gonic/gin"
	"rincon/config"
	"rincon/controller"
	"rincon/service"
	"rincon/utils"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	r.Use(utils.JaegerPropogator())
	return r
}

func main() {
	utils.InitializeLogger()
	defer utils.Logger.Sync()

	router = setupRouter()
	service.InitializeDB()
	service.ConnectDiscord()
	controller.RegisterSelf()
	service.SetupGomailClient()
	if config.Env == "PROD" {
		controller.RegisterStatusCronJob()
	}
	utils.InitializeJaeger()

	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
