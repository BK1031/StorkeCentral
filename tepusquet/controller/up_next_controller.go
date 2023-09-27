package controller

import (
	"github.com/gin-gonic/gin"
	cron "github.com/robfig/cron/v3"
	"net/http"
	"strconv"
	"tepusquet/config"
	"tepusquet/service"
)

func GetUpNextForUser(c *gin.Context) {
	result := service.GetUpNextForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func GetUpNextSubscriptionsForUser(c *gin.Context) {
	result := service.GetUpNextSubscriptionsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func SetUpNextSubscriptionsForUser(c *gin.Context) {
	var subscriptions []string
	if err := c.ShouldBindJSON(&subscriptions); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	service.RemoveUpNextSubscriptionsForUser(c.Param("userID"))
	if err := service.SetUpNextSubscriptionsForUser(c.Param("userID"), subscriptions); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, service.GetUpNextSubscriptionsForUser(c.Param("userID")))
}

func RegisterUpNextCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc(config.UpNextUpdateCron, func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Up Next CRON Job")
		println("Starting Up Next CRON Job...")
		service.FetchUpNextForAllUsers()
		println("Finished Up Next CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Fetched Up Next schedules!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled with cron expression: " + config.UpNextUpdateCron)
}
