package model

import "time"

type Course struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Name      string    `json:"title"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}
