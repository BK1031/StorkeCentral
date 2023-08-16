package main

import (
	"gaviota/config"
	"gaviota/controller"
	"gaviota/service"
	"gaviota/utils"
	"github.com/gin-gonic/gin"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	r.Use(utils.JaegerPropogator())
	r.Use(controller.AuthChecker())
	return r
}

func main() {
	utils.InitializeLogger()
	defer utils.Logger.Sync()

	router = setupRouter()
	service.InitializeDB()
	service.RegisterRincon()
	service.InitializeFirebase()
	service.ConnectDiscord()
	service.InitializeColly()
	controller.RegisterArticleCronJob()
	utils.InitializeJaeger()

	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
