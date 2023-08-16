package service

import (
	"encoding/json"
	"github.com/google/uuid"
	"sort"
	"strconv"
	"sync"
	"tepusquet/config"
	"tepusquet/model"
	"time"
)

func CheckUpNextNotificationsForAllUsers(wg *sync.WaitGroup) {
	defer wg.Done()
	var users []string
	result := DB.Select("DISTINCT user_id").Where("quarter = ?", config.CurrentQuarter).Find(&model.UserScheduleItem{}).Pluck("user_id", &users)
	if result.Error != nil {
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Checking notifications for "+strconv.Itoa(len(users))+" users with schedules this quarter")
	notificationCount := 0
	for _, id := range users {
		if CheckUpNextNotificationsForUserForQuarter(id, config.CurrentQuarter) {
			notificationCount++
		}
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Sent "+strconv.Itoa(notificationCount)+" schedule notifications")
}

func CheckUpNextNotificationsForUserForQuarter(userID string, quarter string) bool {
	sentNotif := false
	schedule := GetUpNextForUserForQuarter(userID, quarter)
	sort.Slice(schedule, func(i, j int) bool {
		return schedule[i].StartTime.Before(schedule[j].StartTime)
	})
	for _, s := range schedule {
		if s.StartTime.After(time.Now()) {
			delta := int(s.StartTime.Sub(time.Now()).Minutes())
			notificationSetting := GetNotificationSettingForUser(userID)
			if notificationSetting != 0 {
				if delta <= notificationSetting+1 && delta >= notificationSetting-1 {
					mirandaBody, _ := json.Marshal(map[string]interface{}{
						"id":          uuid.New(),
						"user_id":     userID,
						"sender":      "Tepusquet",
						"title":       "Class in " + strconv.Itoa(delta) + " minutes",
						"body":        "You have " + s.Title + " at " + s.StartTime.Format("3:04PM") + "!",
						"picture_url": "",
						"launch_url":  "",
						"route":       "/schedule/view/" + s.Title,
						"priority":    "HIGH",
						"push":        true,
						"read":        false,
					})
					SendMirandaNotification(mirandaBody)
					sentNotif = true
				}
			}
			println(userID + " next class is " + s.Title + " at " + s.StartTime.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
			_, _ = Discord.ChannelMessageSend(config.DiscordChannel, userID+" next class is "+s.Title+" at "+s.StartTime.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
			return sentNotif
		} else if s.StartTime.Before(time.Now()) && s.EndTime.After(time.Now()) {
			println(userID + " is in class " + s.Title + " until " + s.EndTime.Format("3:04PM"))
			_, _ = Discord.ChannelMessageSend(config.DiscordChannel, userID+" is in class "+s.Title+" until "+s.EndTime.Format("3:04PM"))
			return sentNotif
		}
	}
	println(userID + " has no more classes today!")
	return sentNotif
}

func CheckPasstimeNotificationsForAllUsersForQuarter(quarter string, wg *sync.WaitGroup) {
	defer wg.Done()
	notificationCount := 0
	passtimes := GetAllPasstimesForQuarter(quarter)
	for _, p := range passtimes {
		if p.PassOneStart.Add(time.Minute).After(time.Now()) {
			delta := int(p.PassOneStart.Sub(time.Now()).Minutes())
			// Will sequentially send notifications at 5 minute intervals from 15 minutes.
			if delta <= 16 {
				// 15 minute reminder
				mirandaBody, _ := json.Marshal(map[string]interface{}{
					"id":          uuid.New(),
					"user_id":     p.UserID,
					"sender":      "Tepusquet",
					"title":       "Pass 1 in " + strconv.Itoa(delta) + " minutes",
					"body":        "Your Registration Pass 1 starts at " + p.PassOneStart.Format("3:04PM") + "!",
					"picture_url": "",
					"launch_url":  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
					"route":       "",
					"priority":    "HIGH",
					"push":        true,
					"read":        false,
				})
				SendMirandaNotification(mirandaBody)
				println(p.UserID + " Pass 1 at " + p.PassOneStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
				_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 1 at "+p.PassOneStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
				notificationCount++
			}
		} else if p.PassTwoStart.Add(time.Minute).After(time.Now()) {
			delta := int(p.PassTwoStart.Sub(time.Now()).Minutes())
			// Will sequentially send notifications at 5 minute intervals from 15 minutes.
			if delta <= 16 {
				// 15 minute reminder
				mirandaBody, _ := json.Marshal(map[string]interface{}{
					"id":          uuid.New(),
					"user_id":     p.UserID,
					"sender":      "Tepusquet",
					"title":       "Pass 2 in " + strconv.Itoa(delta) + " minutes",
					"body":        "Your Registration Pass 2 starts at " + p.PassTwoStart.Format("3:04PM") + "!",
					"picture_url": "",
					"launch_url":  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
					"route":       "",
					"priority":    "HIGH",
					"push":        true,
					"read":        false,
				})
				SendMirandaNotification(mirandaBody)
				println(p.UserID + " Pass 2 at " + p.PassTwoStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
				_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 2 at "+p.PassTwoStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
				notificationCount++
			}
		} else if p.PassThreeStart.Add(time.Minute).After(time.Now()) {
			delta := int(p.PassThreeStart.Sub(time.Now()).Minutes())
			// Will sequentially send notifications at 5 minute intervals from 15 minutes.
			if delta <= 16 {
				// 15 minute reminder
				mirandaBody, _ := json.Marshal(map[string]interface{}{
					"id":          uuid.New(),
					"user_id":     p.UserID,
					"sender":      "Tepusquet",
					"title":       "Pass 3 in " + strconv.Itoa(delta) + " minutes",
					"body":        "Your Registration Pass 3 starts at " + p.PassThreeStart.Format("3:04PM") + "!",
					"picture_url": "",
					"launch_url":  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
					"route":       "",
					"priority":    "HIGH",
					"push":        true,
					"read":        false,
				})
				SendMirandaNotification(mirandaBody)
				println(p.UserID + " Pass 3 at " + p.PassThreeStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
				_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 3 at "+p.PassThreeStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
				notificationCount++
			}
		}
	}
	if notificationCount != 0 {
		_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Sent "+strconv.Itoa(notificationCount)+" passtime notifications")
	}
}

func GetNotificationSettingForUser(userID string) int {
	var setting string
	result := DB.Table("user_privacy").Select("schedule_reminders").Where("user_id = ?", userID).Scan(&setting)
	if result.Error != nil {
	}
	return convertNotificationSetting(setting)
}

// Helper function to convert the notification setting to int
func convertNotificationSetting(setting string) int {
	if setting == "ALERT_15" {
		return 15
	} else if setting == "ALERT_10" {
		return 10
	} else if setting == "ALERT_5" {
		return 5
	} else {
		return 0
	}
}
