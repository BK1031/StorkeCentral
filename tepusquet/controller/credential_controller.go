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

	result := service.GetCredentialForUser(c.Param("userID"), c.GetHeader("SC-Device-Key"))
	if result.UserID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "Credentials not found for user: " + c.Param("userID")})
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
	// Set the user id to ensure that the user can only set their own credentials
	input.UserID = c.Param("userID")
	if err := service.SetCredentialForUser(input); err != nil {
		utils.SugarLogger.Errorln("Error setting credentials for user " + input.UserID + ": " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	utils.SugarLogger.Infoln("Credentials set for user " + input.UserID)
	// Verify that the credentials are valid
	deviceKey := c.GetHeader("SC-Device-Key")
	// Check if credentials are valid
	creds := service.GetCredentialForUser(input.UserID, deviceKey)
	if creds.Username == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "Credentials not found for user, please set them first"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Credentials encrypted and stored"})

	//if service.VerifyCredential(creds, 0) {
	//	utils.SugarLogger.Infoln("Credentials are valid!")
	//	c.JSON(http.StatusOK, gin.H{"message": "Credentials encrypted and stored"})
	//	return
	//}
	//// If not valid, delete the credentials and return an error
	//utils.SugarLogger.Errorln("Invalid credentials, deleting...")
	//service.DeleteCredentialForUser(input.UserID)
	//c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid credentials"})
	return
}
