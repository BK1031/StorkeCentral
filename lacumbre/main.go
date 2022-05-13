package main

import (
	"github.com/gin-gonic/gin"
	"lacumbre/config"
	"lacumbre/controller"
	"lacumbre/service"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	return r
}

func main() {
	router = setupRouter()
	service.InitializeDB()
	service.ConnectDiscord()
	service.RegisterRincon()
	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
