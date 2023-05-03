package controller

import (
	"github.com/gin-gonic/gin"
	cron "github.com/robfig/cron/v3"
	"net/http"
	"strconv"
	"tepusquet/config"
	"tepusquet/service"
)

func GetUpNextForUserForQuarter(c *gin.Context) {
	result := service.GetUpNextForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	c.JSON(http.StatusOK, result)
}

func RegisterUpNextCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc("@every "+config.UpNextUpdateDelay+"s", func() {
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
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.UpNextUpdateDelay + "s")
}
