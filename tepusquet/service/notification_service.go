package service

import (
	"github.com/google/uuid"
	"sort"
	"strconv"
	"sync"
	"tepusquet/config"
	"tepusquet/model"
	"time"
)

func CheckUpNextNotificationsForAllUsers(og *sync.WaitGroup) {
	defer og.Done()
	var users []string
	result := DB.Select("DISTINCT user_id").Where("quarter = ?", config.CurrentQuarter).Find(&model.UserScheduleItem{}).Pluck("user_id", &users)
	if result.Error != nil {
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Checking notifications for "+strconv.Itoa(len(users))+" users with schedules this quarter ("+config.CurrentQuarter+")")
	var wg sync.WaitGroup
	for _, id := range users {
		wg.Add(1)
		id := id
		go func() {
			defer wg.Done()
			CheckUpNextNotificationsForUserForQuarter(id)
		}()
	}
	wg.Wait()
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Finished sending schedule notifications")
}

func CheckUpNextNotificationsForUserForQuarter(userID string) bool {
	sentNotif := false
	inClass := false
	schedule := GetUpNextForUser(userID)
	sort.Slice(schedule, func(i, j int) bool {
		return schedule[i].StartTime.Before(schedule[j].StartTime)
	})
	for _, s := range schedule {
		if s.StartTime.After(time.Now()) {
			delta := int(s.StartTime.Sub(time.Now()).Minutes()) + 1
			notificationSetting := GetScheduleNotificationSettingForUser(userID)
			if notificationSetting != 0 {
				if delta <= notificationSetting+1 && delta >= notificationSetting-1 {
					notification := MirandaNotification{
						ID:         uuid.New().String(),
						UserID:     userID,
						Sender:     config.Service.Name,
						Title:      "Class in " + strconv.Itoa(delta) + " minutes",
						Body:       "You have " + s.Title + " at " + s.StartTime.Format("3:04PM") + "!",
						PictureUrl: "",
						LaunchUrl:  "",
						Route:      "/schedule/view/" + s.Title,
						Priority:   "HIGH",
						Push:       true,
						Read:       false,
					}
					SendMirandaNotification(notification, "", "")
					sentNotif = true
				}
			}
			if !inClass {
				// Only send next class log info if user is not currently in a previous class
				println(userID + " next class is " + s.Title + " at " + s.StartTime.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)! Sent Notif: " + strconv.FormatBool(sentNotif))
				if sentNotif {
					_, _ = Discord.ChannelMessageSend(config.DiscordChannel, userID+" next class is "+s.Title+" at "+s.StartTime.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)! [SENT NOTIFICATION]")
				} else {
					_, _ = Discord.ChannelMessageSend(config.DiscordChannel, userID+" next class is "+s.Title+" at "+s.StartTime.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
				}
			}
			return sentNotif
		} else if s.StartTime.Before(time.Now()) && s.EndTime.After(time.Now()) {
			println(userID + " is in class " + s.Title + " until " + s.EndTime.Format("3:04PM"))
			_, _ = Discord.ChannelMessageSend(config.DiscordChannel, userID+" is in class "+s.Title+" until "+s.EndTime.Format("3:04PM"))
			inClass = true
			// Restart for-loop since next class notification time may overlap with current class period
		}
	}
	println(userID + " has no more classes today!")
	return sentNotif
}

func CheckPasstimeNotificationsForAllUsers(og *sync.WaitGroup) {
	defer og.Done()
	passtimes := GetAllPasstimesForQuarter(config.CurrentPasstimeQuarter)
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Checking passtimes for "+strconv.Itoa(len(passtimes))+" users with passtimes this quarter ("+config.CurrentPasstimeQuarter+")")
	var wg sync.WaitGroup
	for _, p := range passtimes {
		wg.Add(1)
		p := p
		go func() {
			defer wg.Done()
			if GetPasstimeNotificationSettingForUser(p.UserID) {
				if p.PassOneStart.Add(time.Minute).After(time.Now()) {
					delta := int(p.PassOneStart.Sub(time.Now()).Minutes())
					// Will sequentially send notifications at 5 minute intervals from 15 minutes.
					if delta <= 16 {
						// 15 minute reminder
						notification := MirandaNotification{
							ID:         uuid.New().String(),
							UserID:     p.UserID,
							Sender:     config.Service.Name,
							Title:      "Pass 1 in " + strconv.Itoa(delta) + " minutes",
							Body:       "Your Registration Pass 1 starts at " + p.PassOneStart.Format("3:04PM") + "!",
							PictureUrl: "",
							LaunchUrl:  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
							Route:      "",
							Priority:   "HIGH",
							Push:       true,
							Read:       false,
						}
						SendMirandaNotification(notification, "", "")
						println(p.UserID + " Pass 1 at " + p.PassOneStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
						_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 1 at "+p.PassOneStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
					}
				} else if p.PassTwoStart.Add(time.Minute).After(time.Now()) {
					delta := int(p.PassTwoStart.Sub(time.Now()).Minutes())
					// Will sequentially send notifications at 5 minute intervals from 15 minutes.
					if delta <= 16 {
						// 15 minute reminder
						notification := MirandaNotification{
							ID:         uuid.New().String(),
							UserID:     p.UserID,
							Sender:     config.Service.Name,
							Title:      "Pass 2 in " + strconv.Itoa(delta) + " minutes",
							Body:       "Your Registration Pass 2 starts at " + p.PassTwoStart.Format("3:04PM") + "!",
							PictureUrl: "",
							LaunchUrl:  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
							Route:      "",
							Priority:   "HIGH",
							Push:       true,
							Read:       false,
						}
						SendMirandaNotification(notification, "", "")
						println(p.UserID + " Pass 2 at " + p.PassTwoStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
						_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 2 at "+p.PassTwoStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
					}
				} else if p.PassThreeStart.Add(time.Minute).After(time.Now()) {
					delta := int(p.PassThreeStart.Sub(time.Now()).Minutes())
					println(delta)
					// Will sequentially send notifications at 5 minute intervals from 15 minutes.
					if delta <= 16 {
						// 15 minute reminder
						notification := MirandaNotification{
							ID:         uuid.New().String(),
							UserID:     p.UserID,
							Sender:     config.Service.Name,
							Title:      "Pass 3 in " + strconv.Itoa(delta) + " minutes",
							Body:       "Your Registration Pass 3 starts at " + p.PassThreeStart.Format("3:04PM") + "!",
							PictureUrl: "",
							LaunchUrl:  "https://my.sa.ucsb.edu/gold/StudentSchedule.aspx",
							Route:      "",
							Priority:   "HIGH",
							Push:       true,
							Read:       false,
						}
						SendMirandaNotification(notification, "", "")
						println(p.UserID + " Pass 3 at " + p.PassThreeStart.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
						_, _ = Discord.ChannelMessageSend(config.DiscordChannel, p.UserID+" Pass 3 at "+p.PassThreeStart.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
					}
				}
			}
		}()
	}
	wg.Wait()
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Finished sending passtime notifications")
}

func CheckFinalNotificationsForAllUsers(og *sync.WaitGroup) {
	defer og.Done()
	finals := GetAllFinalsForQuarter(config.CurrentQuarter)
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Checking finals for "+strconv.Itoa(len(finals))+" users with finals this quarter ("+config.CurrentQuarter+")")
	var wg sync.WaitGroup
	for _, f := range finals {
		wg.Add(1)
		f := f
		go func() {
			defer wg.Done()
			if f.StartTime.After(time.Now()) {
				delta := int(f.StartTime.Sub(time.Now()).Minutes()) + 1
				notificationSetting := GetFinalNotificationSettingForUser(f.UserID)
				if notificationSetting != 0 {
					if delta <= notificationSetting+1 && delta >= notificationSetting-1 {
						notification := MirandaNotification{
							ID:         uuid.New().String(),
							UserID:     f.UserID,
							Sender:     config.Service.Name,
							Title:      f.Title + " Final in " + strconv.Itoa(delta) + " minutes",
							Body:       "Your " + f.Title + " final is at " + f.StartTime.Format("3:04PM") + ". Good luck!",
							PictureUrl: "",
							LaunchUrl:  "",
							Route:      "/schedule/view/" + f.Title,
							Priority:   "HIGH",
							Push:       true,
							Read:       false,
						}
						SendMirandaNotification(notification, "", "")
						println(f.UserID + " has " + f.Title + " final at " + f.StartTime.Format("3:04PM") + " (" + strconv.Itoa(delta) + " minutes)!")
						_, _ = Discord.ChannelMessageSend(config.DiscordChannel, f.UserID+" has "+f.Title+" final at "+f.StartTime.Format("3:04PM")+" ("+strconv.Itoa(delta)+" minutes)!")
					}
				}
			}
		}()
	}
	wg.Wait()
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Finished sending final notifications")
}

func GetScheduleNotificationSettingForUser(userID string) int {
	var setting string
	result := DB.Table("user_privacy").Select("schedule_reminders").Where("user_id = ?", userID).Scan(&setting)
	if result.Error != nil {
	}
	return convertNotificationSetting(setting)
}

func GetPasstimeNotificationSettingForUser(userID string) bool {
	var setting string
	result := DB.Table("user_privacy").Select("passtime_reminders").Where("user_id = ?", userID).Scan(&setting)
	if result.Error != nil {
	}
	return setting == "ENABLED"
}

func GetFinalNotificationSettingForUser(userID string) int {
	var setting string
	result := DB.Table("user_privacy").Select("final_reminders").Where("user_id = ?", userID).Scan(&setting)
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
