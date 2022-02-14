package models

type Service struct {
	ID uint `json:"id" gorm:"primary_key`
	Name string `json:"name"`
	URL string `json:"url"`
	Port uint `json:"port"`
}
