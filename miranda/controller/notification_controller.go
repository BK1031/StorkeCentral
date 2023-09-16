package controller

import (
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"miranda/model"
	"miranda/service"
	"miranda/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetAllNotificationsForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllNotificationsForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllNotificationsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetAllUnreadNotificationsForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllUnreadNotificationsForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllUnreadNotificationsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetNotificationByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetNotificationByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetNotificationByID(c.Param("notificationID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No notification found with given id: " + c.Param("notificationID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func CreateNotification(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateNotification", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.Notification
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	if err := service.CreateNotification(input); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, service.GetNotificationByID(input.ID))
}
