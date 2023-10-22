package model

import "time"

type UserFinal struct {
	UserID    string    `json:"user_id"`
	Title     string    `json:"title"`
	Name      string    `json:"name"`
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Quarter   string    `json:"quarter"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserFinal) TableName() string {
	return "user_final"
}
