package model

import "time"

type Login struct {
	ID string `gorm:"primaryKey" json:"id"`
	UserID string `json:"user_id"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Agent string `json:"agent"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Login) TableName() string {
	return "user_login"
}
