package main

import (
	"github.com/gin-gonic/gin"
	"rincon/config"
	"rincon/controller"
	"rincon/service"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	r := gin.Default()
	return r
}

func main() {
	router = setupRouter()
	service.InitializeDB()
	service.SetupGomailClient()
	service.ConnectDiscord()
	controller.InitializeRoutes(router)
	controller.RegisterSelf()
	router.Run(":" + config.Port)
}
