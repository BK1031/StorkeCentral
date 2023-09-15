package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/service"
	"lacumbre/utils"
	"net/http"
)

func GetUserLogins(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetUserLogins", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetLoginsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateUserLogin(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateUserLogin", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.Login
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	user := service.GetUserByID(input.UserID)
	if user.ID != "" {
		utils.SugarLogger.Infoln("New user login recorded")
		input.ID = uuid.New().String()
		if err := service.CreateLogin(input); err != nil {
			c.JSON(http.StatusInternalServerError, err)
			return
		}
		go service.Discord.ChannelMessageSend(config.DiscordChannel, user.String()+" just logged in from "+input.DeviceName+" ("+input.DeviceVersion+") – "+input.AppVersion)
		c.JSON(http.StatusOK, service.GetLoginByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Failed to find requested user!"})
	}
}
