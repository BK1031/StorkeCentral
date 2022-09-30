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
	if err := service.AddScheduleItemForUserForQuarter(scheduleItem); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.Status(http.StatusOK)
}

func RemoveScheduleForUserForQuarter(c *gin.Context) {
	service.RemoveScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
