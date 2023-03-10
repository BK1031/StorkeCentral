package model

import "time"

type DiningHall struct {
	ID             string    `gorm:"primaryKey" json:"id"`
	Name           string    `json:"name"`
	HasSackMeal    bool      `json:"has_sack_meal"`
	HasTakeoutMeal bool      `json:"has_takeout_meal"`
	HasDiningCam   bool      `json:"has_dining_cam"`
	Latitude       float64   `json:"latitude"`
	Longitude      float64   `json:"longitude"`
	CreatedAt      time.Time `gorm:"autoCreateTime" json:"created_at"`
}
