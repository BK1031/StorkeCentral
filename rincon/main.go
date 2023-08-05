package main

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
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
	r.Use(otelgin.Middleware("Rincon"))
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
