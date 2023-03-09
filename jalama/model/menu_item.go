package model

import "time"

type MenuItem struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	MealID    string    `json:"meal_id"`
	Name      string    `json:"name"`
	Station   string    `json:"station"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}
