package service

import "miranda/model"

func GetDataForNotification(notificationID string) []model.NotificationData {
	var data []model.NotificationData
	result := DB.Where("notification_id = ?", notificationID).Find(&data)
	if result.Error != nil {
	}
	return data
}

func SetDataForNotification(notificationID string, data []model.NotificationData) error {
	DB.Where("notification_id = ?", notificationID).Delete(&model.NotificationData{})
	for _, d := range data {
		if result := DB.Create(&d); result.Error != nil {
			return result.Error
		}
	}
	return nil
}
