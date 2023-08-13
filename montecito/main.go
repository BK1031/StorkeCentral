package main

import (
	"github.com/gin-gonic/gin"
	"montecito/config"
	"montecito/controller"
	"montecito/service"
	"montecito/utils"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.CorsHandler())
	r.Use(controller.RequestLogger())
	r.Use(utils.JaegerPropogator())
	r.Use(controller.APIKeyChecker())
	r.Use(controller.AuthChecker())
	r.Use(controller.ResponseLogger())
	return r
}

func main() {
	utils.InitializeLogger()
	defer utils.Logger.Sync()

	router = setupRouter()
	service.InitializeDB()
	service.RegisterRincon()
	service.GetAllAPIKeys()
	service.InitializeFirebase()
	service.ConnectDiscord()
	utils.InitializeJaeger()

	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}
