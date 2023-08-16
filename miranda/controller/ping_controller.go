package controller

import (
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"miranda/config"
	"miranda/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "Ping", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	c.JSON(http.StatusOK, gin.H{"message": "Miranda v" + config.Version + " is online!"})
}
