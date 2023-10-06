package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/service"
	"tepusquet/utils"
)

func GetPasstimeForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetPasstimeForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetPasstimeForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	if result.UserID != "" {
		c.JSON(http.StatusOK, result)
		return
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Passtime not found for user " + c.Param("userID") + " for quarter " + c.Param("quarter")})
	}
}

func FetchPasstimeForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchPasstimeForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
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
	passtime := service.FetchPasstimeForUserForQuarter(creds, c.Param("quarter"), 0)
	if passtime.UserID == "AUTH ERROR" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Invalid credentials."})
		return
	}
	err := service.CreatePasstimeForUser(passtime)
	if err != nil {
		return
	}
	c.JSON(http.StatusOK, service.GetPasstimeForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}
