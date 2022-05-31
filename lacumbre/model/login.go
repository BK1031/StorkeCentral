package model

import "time"

type Login struct {
	ID string `gorm:"primaryKey" json:"id"`
	UserID string `json:"user_id"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	AppVersion string `json:"app_version"`
	DeviceName string `json:"device_name"`
	DeviceVersion string `json:"device_version"`
	ConnectionType string `json:"connection_type"`
	ConnectionSSID string `json:"connection_ssid"`
	ConnectionIP string `json:"connection_ip"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Login) TableName() string {
	return "user_login"
}
