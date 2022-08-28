package main

import (
	"github.com/gin-gonic/gin"
	"tepusquet/config"
	"tepusquet/controller"
	"tepusquet/service"
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
	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
