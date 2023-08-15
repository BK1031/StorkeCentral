package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"jalama/service"
	"jalama/utils"
	"net/http"
)

func GetAllDiningHalls(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllDiningHalls", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllDiningHalls()
	c.JSON(http.StatusOK, result)
}

func GetDiningHall(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetDiningHall", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetDiningHall(c.Param("diningHallID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No dining hall found with given id: " + c.Param("diningHallID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func FetchAllDiningHalls(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchAllDiningHalls", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.FetchAllDiningHalls()
	c.JSON(http.StatusOK, result)
}
