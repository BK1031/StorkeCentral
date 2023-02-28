package controller

import (
	"miranda/model"
	"miranda/service"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetAllNotificationsForUser(c *gin.Context) {
	result := service.GetAllNotificationsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetAllUnreadNotificationsForUser(c *gin.Context) {
	result := service.GetAllUnreadNotificationsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetNotificationByID(c *gin.Context) {
	result := service.GetNotificationByID(c.Param("notificationID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No notification found with given id: " + c.Param("notificationID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func CreateNotification(c *gin.Context) {
	var input model.Notification
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := service.CreateNotification(input); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, service.GetNotificationByID(input.ID))
}