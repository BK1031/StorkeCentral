package model

import "time"

type Article struct {
	ID         string    `gorm:"primaryKey" json:"id"`
	Title      string    `json:"title"`
	ByLine     string    `json:"by_line"`
	Excerpt    string    `json:"excerpt"`
	PictureURL string    `json:"picture_url"`
	Date       string    `json:"date"`
	ArticleURL string    `json:"article_url"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Article) TableName() string {
	return "article"
}
