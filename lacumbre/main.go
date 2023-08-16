package main

import (
	"github.com/gin-gonic/gin"
	"lacumbre/config"
	"lacumbre/controller"
	"lacumbre/service"
	"lacumbre/utils"
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
	utils.InitializeJaeger()

	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
