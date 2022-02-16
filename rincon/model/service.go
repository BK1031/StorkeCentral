package model

import "time"

type Service struct {
	ID uint `gorm:"primaryKey" json:"id"`
	Name string `json:"name"`
	URL string `json:"url"`
	Port uint `json:"port"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Service) TableName() string {
	return "service"
}