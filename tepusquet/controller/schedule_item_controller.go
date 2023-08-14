package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"tepusquet/model"
	"tepusquet/service"
	"tepusquet/utils"
)

func GetScheduleForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetScheduleForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.JSON(http.StatusOK, result)
}

func SetScheduleForUserForQuarter(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "SetScheduleForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

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
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "RemoveScheduleForUserForQuarter", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	service.RemoveScheduleForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.Status(http.StatusOK)
}
