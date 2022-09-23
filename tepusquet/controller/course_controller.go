package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/service"
)

func GetCoursesForUser(c *gin.Context) {
	result := service.GetCoursesForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func FetchCoursesForUser(c *gin.Context) {
	//courses := service.FetchCoursesForUser(c.Param("username"), c.Param("password"))

	c.Status(http.StatusOK)
}

func RemoveCourseForUser(c *gin.Context) {
	service.RemoveCourseForUser(c.Param("userID"), c.Param("courseID"))
	c.Status(http.StatusOK)
}
