package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/service"
)

func GetAllCoursesForUser(c *gin.Context) {
	result := service.GetAllCoursesForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetCoursesForUserForQuarter(c *gin.Context) {
	result := service.GetCoursesForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.JSON(http.StatusOK, result)
}

func FetchCoursesForUserForQuarter(c *gin.Context) {
	creds := service.GetCredentialForUser(c.Param("userID"))
	if creds.Username == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "Credentials not found for user, please set them first"})
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
	service.RemoveCourseForUserForQuarter(c.Param("userID"), c.Param("courseID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
