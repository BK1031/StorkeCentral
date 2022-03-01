package model

import "time"

type Service struct {
	ID int `gorm:"primaryKey" json:"id"`
	Name string `json:"name"`
	Version string `json:"version"`
	URL string `json:"url"`
	Port int `json:"port"`
	StatusEmail string `json:"status_email"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Service) TableName() string {
	return "service"
}