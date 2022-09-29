package model

import "time"

type UserScheduleItem struct {
	UserID    string    `json:"user_id"`
	CourseID  string    `json:"course_id"`
	Title     string    `json:"title"`
	Building  string    `json:"building"`
	Room      string    `json:"room"`
	StartTime string    `json:"start_time"`
	EndTime   string    `json:"end_time"`
	Days      string    `json:"days"`
	Quarter   string    `json:"quarter"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserScheduleItem) TableName() string {
	return "user_schedule_item"
}
