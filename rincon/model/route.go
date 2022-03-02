package model

import "time"

type Route struct {
	Route string `gorm:"primaryKey" json:"route"`
	ServiceName string `json:"service_name"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Route) TableName() string {
	return "service_route"
}
