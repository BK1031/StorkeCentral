package model

import "time"

type Friend struct {
	FromUserID string    `gorm:"primaryKey" json:"from_user_id"`
	ToUserID   string    `gorm:"primaryKey" json:"to_user_id"`
	Status     string    `json:"status"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
	User       User      `gorm:"-:all" json:"user"`
}

func (Friend) TableName() string {
	return "user_friend"
}
