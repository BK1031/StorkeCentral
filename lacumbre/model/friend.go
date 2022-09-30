package model

import "time"

type Friend struct {
	ID         string    `gorm:"primaryKey" json:"id"`
	FromUserID string    `json:"from_user_id"`
	ToUserID   string    `json:"to_user_id"`
	Status     string    `json:"status"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
	User       User      `gorm:"-:all" json:"user"`
}

func (Friend) TableName() string {
	return "user_friend"
}
