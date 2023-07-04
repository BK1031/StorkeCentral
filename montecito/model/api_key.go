package model

import "time"

type APIKey struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Purpose   string    `json:"purpose"`
	UserID    string    `json:"user_id"`
	Scopes    string    `json:"scopes"`
	Expires   time.Time `json:"expires"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (APIKey) TableName() string {
	return "api_key"
}
