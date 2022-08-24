package main

import (
	"gaviota/config"
	"gaviota/controller"
	"gaviota/service"
	"github.com/gin-gonic/gin"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	r.Use(controller.AuthChecker())
	return r
}

func main() {
	router = setupRouter()
	service.InitializeDB()
	service.InitializeFirebase()
	service.ConnectDiscord()
	service.RegisterRincon()
	service.InitializeColly()
	controller.RegisterArticleCronJob()
	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
