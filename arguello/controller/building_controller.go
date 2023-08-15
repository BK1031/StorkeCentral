package controller

import (
	"arguello/service"
	"arguello/utils"
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
)

func GetAllBuildings(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllBuildings", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllBuildings()
	c.JSON(http.StatusOK, result)
}

func GetBuildingByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetBuildingByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetBuildingByID(c.Param("buildingID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No building found with given id: " + c.Param("buildingID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}
