package controller

import (
	cron "github.com/robfig/cron/v3"
	"strconv"
	"sync"
	"tepusquet/config"
	"tepusquet/service"
)

func RegisterNotificationsCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc(config.NotificationCron, func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Notifications CRON Job")
		println("Starting Notifications CRON Job...")
		var wg sync.WaitGroup
		wg.Add(2)
		go service.CheckUpNextNotificationsForAllUsers(&wg)
		go service.CheckPasstimeNotificationsForAllUsers(&wg)
		wg.Wait()
		println("Finished Notifications CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Finished notifications job!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled with cron expression: " + config.NotificationCron)
}
