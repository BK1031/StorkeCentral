package controller

import (
	"encoding/json"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"montecito/config"
	"montecito/model"
	"montecito/utils"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "Ping", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	startTime, _ := c.Get("startTime")
	c.AbortWithStatusJSON(200, model.Response{
		Status:    "SUCCESS",
		Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
		Gateway:   "Montecito v" + config.Version,
		Service:   "Montecito v" + config.Version,
		Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
		Data:      json.RawMessage("{\"message\": \"Montecito v" + config.Version + " is online!\"}"),
	})
}
