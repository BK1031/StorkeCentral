package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/model"
	"tepusquet/service"
	"tepusquet/utils"
)

func GetCredentialForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetCredentialForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetCredentialForUser(c.Param("userID"))
	if result.UserID == "" {
		c.Status(http.StatusNotFound)
		return
	}
	c.JSON(http.StatusOK, result)
}

func SetCredentialForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "SetCredentialForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.UserCredential
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	// Check if credentials are valid
	if !service.VerifyCredential(input, 0) {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid credentials"})
		return
	}
	// Set the user id to ensure that the user can only set their own credentials
	input.UserID = c.Param("userID")
	if err := service.SetCredentialForUser(input); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Credentials encrypted and stored"})
}
