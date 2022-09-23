package model

import "time"

type UserCredential struct {
	UserID        string    `gorm:"primaryKey" json:"user_id"`
	Username      string    `json:"username"`
	Password      string    `json:"password"`
	EncryptionKey string    `json:"encryption_key"`
	CreatedAt     time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (UserCredential) TableName() string {
	return "user_credential"
}
