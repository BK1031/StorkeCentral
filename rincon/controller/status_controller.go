package controller

import (
	"github.com/gin-gonic/gin"
	cron "github.com/robfig/cron/v3"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"rincon/config"
	"rincon/service"
	"strconv"
)

func GetAllServiceStatus(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetAllServiceStatus", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	returnList := []gin.H{}
	services := service.GetAllServices()
	if len(services) == 0 {
		c.JSON(http.StatusNotFound, returnList)
		return
	}
	for i, s := range services {
		println(i, s.Name)
		returnList = append(returnList, service.GetServiceStatus(s))
	}
	c.JSON(http.StatusOK, returnList)
}

func GetServiceStatus(c *gin.Context) {
	// Start tracing span
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(c.Request.Context(), "GetServiceStatus", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	returnList := []gin.H{}
	services := service.GetServiceByName(c.Param("name"))
	if len(services) == 0 {
		c.JSON(http.StatusNotFound, returnList)
		return
	}
	for i, s := range services {
		println(i, s.Name)
		returnList = append(returnList, service.GetServiceStatus(s))
	}
	c.JSON(http.StatusOK, returnList)
}

func RegisterStatusCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc("@every "+config.RegistryUpdateDelay+"s", func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Status CRON Job")
		println("Starting Status CRON Job...")
		services := service.GetAllServices()
		for i, s := range services {
			println(i, s.Name)
			service.GetServiceStatus(s)
		}
		println("Finished Status CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Finished Status CRON Job!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.RegistryUpdateDelay + "s")
}
