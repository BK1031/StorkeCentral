package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/service"
	"tepusquet/utils"
)

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
	}
	finals := service.FetchFinalsForUserForQuarter(creds, c.Param("quarter"), 0)
	if len(finals) > 0 && finals[0].UserID == "AUTH ERROR" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid credentials."})
		return
	}
	err := service.CreateAllFinalsForUser(finals)
	if err != nil {
		utils.SugarLogger.Errorln("error creating finals for user: " + err.Error())
		return
	}
	c.JSON(http.StatusOK, service.GetFinalsForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}

func GetFinalsForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetFinalsForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	c.JSON(http.StatusOK, service.GetFinalsForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}
