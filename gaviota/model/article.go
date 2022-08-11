package model

import "time"

type Article struct {
	ID         string    `gorm:"primaryKey" json:"id"`
	Title      string    `json:"title"`
	ByLine     string    `json:"by_line"`
	Excerpt    string    `json:"author_name"`
	PictureURL string    `json:"author_profile_picture_url"`
	Date       string    `json:"date"`
	ArticleURL string    `json:"article_url"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
}
