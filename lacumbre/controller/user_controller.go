package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"lacumbre/model"
	"lacumbre/service"
	"lacumbre/utils"
	"net/http"
)

func GetAllUsers(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllUsers", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllUsers()
	c.JSON(http.StatusOK, result)
}

func GetUserByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetUserByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetUserByID(c.Param("userID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No user found with given id: " + c.Param("userID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func CreateUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.User
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	// Set the user id to ensure that the user can only modify their own account
	input.ID = c.Param("userID")
	if err := service.CreateUser(input); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	c.JSON(http.StatusOK, service.GetUserByID(input.ID))
}
