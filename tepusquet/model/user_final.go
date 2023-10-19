package model

import "time"

type UserFinal struct {
	UserID    string    `json:"user_id"`
	CourseID  string    `json:"course_id"`
	Title     string    `json:"title"`
	StartTime string    `json:"start_time"`
	EndTime   string    `json:"end_time"`
	Quarter   string    `json:"quarter"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserFinal) TableName() string {
	return "user_final"
}
