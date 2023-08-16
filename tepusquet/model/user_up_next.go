package model

import "time"

type UserUpNext struct {
	UserID    string    `json:"user_id"`
	CourseID  string    `json:"course_id"`
	Title     string    `json:"title"`
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Quarter   string    `json:"quarter"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserUpNext) TableName() string {
	return "user_up_next"
}
