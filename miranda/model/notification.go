package model

import "time"

type Notification struct {
	ID         string             `gorm:"primaryKey" json:"id"`
	UserID     string             `json:"user_id"`
	Sender     string             `json:"sender"`
	Title      string             `json:"title"`
	Body       string             `json:"body"`
	PictureURL string             `json:"picture_url"`
	LaunchURL  string             `json:"launch_url"`
	Route      string             `json:"route"`
	Priority   string             `json:"priority"`
	Push       bool               `json:"push"`
	Read       bool               `json:"read"`
	Data       []NotificationData `gorm:"-" json:"data"`
	CreatedAt  time.Time          `gorm:"autoCreateTime" json:"created_at"`
}

func (Notification) TableName() string {
	return "notification"
}
