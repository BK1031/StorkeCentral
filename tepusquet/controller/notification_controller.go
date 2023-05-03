package controller

import (
	"github.com/robfig/cron/v3"
	"strconv"
	"tepusquet/config"
	"tepusquet/service"
)

func RegisterNotificationsCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc("@every "+config.NotificationUpdateDelay+"s", func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Notifications CRON Job")
		println("Starting Notifications CRON Job...")
		service.CheckUpNextNotificationsForAllUsers()
		println("Finished Notifications CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Finished sending schedules notifications!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.UpNextUpdateDelay + "s")
}
