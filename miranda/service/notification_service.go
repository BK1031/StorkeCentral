package service

import "miranda/model"

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
		if result := DB.Create(&notification); result.Error != nil {
			return result.Error
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
