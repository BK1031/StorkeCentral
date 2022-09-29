package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/model"
	"tepusquet/service"
)

func GetScheduleForUserForQuarter(c *gin.Context) {
	result := service.GetScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.JSON(http.StatusOK, result)
}

func AddScheduleItemForUserForQuarter(c *gin.Context) {
	var scheduleItem model.UserScheduleItem
	if err := c.ShouldBindJSON(&scheduleItem); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	service.RemoveCourseForUserForQuarter(scheduleItem.UserID, scheduleItem.CourseID, scheduleItem.Quarter)
	if err := service.AddScheduleItemForUserForQuarter(scheduleItem); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.Status(http.StatusOK)
}

func RemoveScheduleItemForUserForQuarter(c *gin.Context) {
	service.RemoveScheduleItemForUserForQuarter(c.Param("userID"), c.Param("courseID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
