package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/service"
	"tepusquet/utils"
)

func GetFinalsForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetFinalsForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	c.JSON(http.StatusOK, service.GetFinalsForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}

func FetchFinalsForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchFinalForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	deviceKey := c.GetHeader("SC-Device-Key")
	if deviceKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Device key not set in header"})
		return
	}
	creds := service.GetCredentialForUser(c.Param("userID"), deviceKey)
	if creds.Username == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "Credentials not found for user, please set them first"})
		return
	} else if creds.Username == "error" {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Error decrypting credentials for user, check device key!"})
		return
	}

	status, page := service.LoginGOLD(creds)
	if status == 1 {
		utils.SugarLogger.Errorln("Credentials are invalid!")
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid credentials"})
		return
	} else if status == 2 {
		utils.SugarLogger.Errorln("Duo MFA timed out!")
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Duo MFA prompt timed out"})
		return
	}

	finals := service.FetchFinalsForUserForQuarter(page, creds, c.Param("quarter"), 0)
	err := service.CreateAllFinalsForUser(finals)
	if err != nil {
		utils.SugarLogger.Errorln("error creating finals for user: " + err.Error())
		return
	}
	c.JSON(http.StatusOK, service.GetFinalsForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}
