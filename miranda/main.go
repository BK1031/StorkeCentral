package main

import (
	"miranda/config"
	"miranda/controller"
	"miranda/service"

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
	service.InitializeOneSignal()
	service.ConnectDiscord()
	service.RegisterRincon()
	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
