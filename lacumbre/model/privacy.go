package model

import "time"

type Privacy struct {
	UserID string `json:"user_id"`
	Email string `json:"email"`
	PhoneNumber string `json:"phone_number"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Privacy) TableName() string {
	return "user_privacy"
}

