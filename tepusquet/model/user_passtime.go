package model

import "time"

type UserPasstime struct {
	UserID         string    `json:"user_id"`
	Quarter        string    `json:"quarter"`
	PassOneStart   time.Time `json:"pass_one_start"`
	PassOneEnd     time.Time `json:"pass_one_end"`
	PassTwoStart   time.Time `json:"pass_two_start"`
	PassTwoEnd     time.Time `json:"pass_two_end"`
	PassThreeStart time.Time `json:"pass_three_start"`
	PassThreeEnd   time.Time `json:"pass_three_end"`
	CreatedAt      time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserPasstime) TableName() string {
	return "user_passtime"
}
