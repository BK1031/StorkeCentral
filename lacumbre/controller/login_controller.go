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

func GetAllLogins(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllLogins", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllLogins()
	c.JSON(http.StatusOK, result)
}

func GetLoginsForLastNDays(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetLoginsForLastNDays", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetLoginsForLastNDays(c.Param("days"))
	c.JSON(http.StatusOK, result)
}

func GetUserLogins(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetUserLogins", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetLoginsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetUserLoginsForLastNDays(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetUserLoginsForLastNDays", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetLoginsForUserLastNDays(c.Param("userID"), c.Param("days"))
	c.JSON(http.StatusOK, result)
}

func CreateUserLogin(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateUserLogin", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.Login
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	input.UserID = c.Param("userID")
	user := service.GetUserByID(input.UserID)
	if user.ID != "" {
		utils.SugarLogger.Infoln("New user login recorded")
		input.ID = uuid.New().String()
		if err := service.CreateLogin(input); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
			return
		}
		go service.Discord.ChannelMessageSend(config.DiscordChannel, user.String()+" just logged in from "+input.DeviceName+" ("+input.DeviceVersion+") – "+input.AppVersion)
		c.JSON(http.StatusOK, service.GetLoginByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Failed to find requested user!"})
	}
}
