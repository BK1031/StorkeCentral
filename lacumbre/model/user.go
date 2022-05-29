package model

import "time"

type User struct {
	ID string `gorm:"primaryKey" json:"id"`
	UserName string `gorm:"unique" json:"user_name"`
	FirstName string `json:"first_name"`
	LastName string `json:"last_name"`
	PreferredName string `json:"preferred_name"`
	Pronouns string `json:"pronouns"`
	Email string `gorm:"unique" json:"email"`
	PhoneNumber string `json:"phone_number"`
	ProfilePictureURL string `json:"profile_picture_url"`
	Bio string `json:"bio"`
	Gender string `json:"gender"`
	Roles []Role `gorm:"-" json:"roles"`
	Friends []Friend `gorm:"-" json:"friends"`
	Privacy Privacy `gorm:"-" json:"privacy"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (User) TableName() string {
	return "user"
}

func (user User) String() string {
	return "(" + user.ID + ")" + " " + user.FirstName + " " + user.LastName
}