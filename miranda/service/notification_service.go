package service

import (
	onesignal "github.com/OneSignal/onesignal-go-api"
	"miranda/config"
	"miranda/model"
)

func GetAllNotificationsForUser(userID string) []model.Notification {
	var notifications []model.Notification
	result := DB.Where("user_id = ?", userID).Find(&notifications)
	if result.Error != nil {
	}
	for i := range notifications {
		notifications[i].Data = GetDataForNotification(notifications[i].ID)
	}
	return notifications
}

func GetAllUnreadNotificationsForUser(userID string) []model.Notification {
	var notifications []model.Notification
	result := DB.Where("user_id = ? AND read = ?", userID, false).Find(&notifications)
	if result.Error != nil {
	}
	for i := range notifications {
		notifications[i].Data = GetDataForNotification(notifications[i].ID)
	}
	return notifications
}

func GetNotificationByID(notificationID string) model.Notification {
	var notification model.Notification
	result := DB.Where("id = ?", notificationID).Find(&notification)
	if result.Error != nil {
	}
	notification.Data = GetDataForNotification(notification.ID)
	return notification
}

func CreateNotification(notification model.Notification) error {
	if DB.Where("id = ?", notification.ID).Updates(&notification).RowsAffected == 0 {
		println("New notification created with id: " + notification.ID)
		_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "New notification just created by "+notification.Sender+" for user "+notification.UserID)
		if result := DB.Create(&notification); result.Error != nil {
			return result.Error
		}
		// Create and send OneSignal notification if new notification is created
		if notification.Push {
			osNotification := onesignal.Notification{}
			osNotification.SetAppId(config.OneSignalAppID)
			osNotification.SetHeadings(onesignal.StringMap{En: &notification.Title})
			osNotification.SetContents(onesignal.StringMap{En: &notification.Body})
			// Transfer data from notification to osNotification
			data := make(map[string]interface{})
			for _, d := range notification.Data {
				data[d.Key] = d.Value
			}
			osNotification.SetData(data)
			// Transfer urls that are included
			if notification.LaunchURL != "" {
				osNotification.SetUrl(notification.LaunchURL)
			}
			osNotification.SetIncludePlayerIds([]string{GetPlayerIDForUser(notification.UserID)})
			//if notification.Priority == "HIGH" {
			//	osNotification.SetPriority(10)
			//	osNotification.Set
			//} else {
			//	osNotification.SetPriority(5)
			//}
			CreateOSNotification(&osNotification)
		}
	} else {
		println("Notification with id: " + notification.ID + " has been updated!")
	}
	if len(notification.Data) > 0 {
		println("Notification with id: " + notification.ID + " has non-empty data, setting data in db...")
		if err := SetDataForNotification(notification.ID, notification.Data); err != nil {
			return err
		}
	} else {
		println("Notification with id: " + notification.ID + " has empty data, nothing to do here!")
	}
	return nil
}

func GetPlayerIDForUser(userID string) string {
	var playerID string
	result := DB.Table("user_privacy").Where("user_id = ?", userID).Select("push_notification_token").Row().Scan(&playerID)
	if result != nil {
	}
	return playerID
}
