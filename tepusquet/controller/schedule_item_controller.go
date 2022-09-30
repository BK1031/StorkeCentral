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

func SetScheduleForUserForQuarter(c *gin.Context) {
	var input []model.UserScheduleItem
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": err.Error()})
		return
	}
	service.RemoveScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	if err := service.SetScheduleForUserForQuarter(input); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}
	c.Status(http.StatusOK)
}

func RemoveScheduleForUserForQuarter(c *gin.Context) {
	service.RemoveScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
