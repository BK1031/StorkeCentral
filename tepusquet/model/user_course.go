package model

import "time"

type UserCourse struct {
	UserID    string    `json:"user_id"`
	CourseID  string    `json:"course_id"`
	Quarter   string    `json:"quarter"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserCourse) TableName() string {
	return "user_course"
}
