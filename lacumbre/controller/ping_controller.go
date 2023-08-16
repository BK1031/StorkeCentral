package controller

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"lacumbre/config"
	"lacumbre/utils"
	"net/http"
)

func Ping(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "Ping", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	c.JSON(http.StatusOK, gin.H{"message": "Lacumbre v" + config.Version + " is online!"})
}
