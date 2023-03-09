package model

import "time"

type MenuItem struct {
	MealID    string    `json:"meal_id"`
	Name      string    `json:"name"`
	Station   string    `json:"station"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}
