package model

import "time"

type Service struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Version     string    `json:"version"`
	URL         string    `json:"url"`
	Port        int       `json:"port"`
	StatusEmail string    `json:"status_email"`
	CreatedAt   time.Time `json:"created_at"`
}
