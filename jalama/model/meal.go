package model

import "time"

type Meal struct {
	ID           string     `gorm:"primaryKey" json:"id"`
	Name         string     `json:"name"`
	DiningHallID string     `json:"dining_hall_id"`
	Open         time.Time  `json:"open"`
	Close        time.Time  `json:"close"`
	MenuItems    []MenuItem `gorm:"-" json:"menu_items"`
	CreatedAt    time.Time  `gorm:"autoCreateTime" json:"created_at"`
}
