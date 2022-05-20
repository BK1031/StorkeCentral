package model

import "time"

type Privacy struct {
	UserID string `json:"user_id"`
	Email string `json:"email"`
	PhoneNumber string `json:"phone_number"`
	Location string `json:"location"`
	PushNotifications string `json:"push_notifications"`
	PushNotificationToken string `json:"push_notification_token"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Privacy) TableName() string {
	return "user_privacy"
}

