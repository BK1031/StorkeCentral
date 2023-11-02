package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/service"
	"tepusquet/utils"
)

func GetAllCoursesForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllCoursesForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllCoursesForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetCoursesForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetCoursesForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetCoursesForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.JSON(http.StatusOK, result)
}

func FetchCoursesForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchCoursesForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	deviceKey := c.GetHeader("SC-Device-Key")
	if deviceKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Device key not set in header"})
		return
	}
	creds := service.GetCredentialForUser(c.Param("userID"), deviceKey)
	if creds.Username == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Credentials not found for user, please set them first"})
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

	courses := service.FetchCoursesForUserForQuarter(page, creds, c.Param("quarter"), 0)
	service.RemoveAllCoursesForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	for _, course := range courses {
		service.AddCourseForUser(course)
	}
	c.JSON(http.StatusOK, service.GetCoursesForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}

func RemoveCourseForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "RemoveCourseForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	service.RemoveCourseForUserForQuarter(c.Param("userID"), c.Param("courseID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
