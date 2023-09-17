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

	creds := service.GetCredentialForUser(c.Param("userID"))
	if creds.Username == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Credentials not found for user, please set them first"})
		return
	}
	courses := service.FetchCoursesForUserForQuarter(creds, c.Param("quarter"))
	service.RemoveAllCoursesForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	if len(courses) == 1 && courses[0].UserID == "AUTH ERROR" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "You have entered an invalid UCSB NetID/Password combination, please re-enter and try again."})
		return
	}
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
