package model

import "time"

type Privacy struct {
	UserID                string    `gorm:"primaryKey" json:"user_id"`
	Email                 string    `json:"email"`
	PhoneNumber           string    `json:"phone_number"`
	Pronouns              string    `json:"pronouns"`
	Gender                string    `json:"gender"`
	Location              string    `json:"location"`
	Status                string    `json:"status"`
	PushNotifications     string    `json:"push_notifications"`
	PushNotificationToken string    `json:"push_notification_token"`
	ScheduleReminders     string    `json:"schedule_reminders"`
	PasstimeReminders     string    `json:"passtime_reminders"`
	FinalReminders        string    `json:"final_reminders"`
	UpdatedAt             time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt             time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Privacy) TableName() string {
	return "user_privacy"
}
