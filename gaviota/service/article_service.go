package service

import (
	"crypto/rand"
	"gaviota/model"
	"github.com/gocolly/colly/v2"
)

func GetAllArticles() []model.Article {
	var articles []model.Article
	result := DB.Find(&articles)
	if result.Error != nil {
	}
	return articles
}

func GetArticleByID(articleID string) model.Article {
	var article model.Article
	result := DB.Where("id = ?", articleID).Find(&article)
	if result.Error != nil {
	}
	return article
}

func GetLatestArticle() model.Article {
	var article model.Article
	result := DB.Order("created_at desc").First(&article)
	if result.Error != nil {
	}
	return article
}

func CreateArticle(article model.Article) error {
	if DB.Where("id = ?", article.ID).Updates(&article).RowsAffected == 0 {
		println("New article created with id: " + article.ID)
		if result := DB.Create(&article); result.Error != nil {
			return result.Error
		}
		DiscordLogNewArticle(article)
	} else {
		println("Article with id: " + article.ID + " has been updated!")
	}
	return nil
}

func FetchLatestArticle() model.Article {
	var article model.Article
	c := collyCollector.Clone()
	c.AllowURLRevisit = true
	c.OnHTML(".featured-image", func(e *colly.HTMLElement) {
		article.PictureURL = e.ChildAttr("img[src]", "src")
		article.ArticleURL = e.Request.AbsoluteURL(e.ChildAttr("a[href]", "href"))
	})
	c.OnHTML(".primary-featured .featured-headline", func(e *colly.HTMLElement) {
		article.Title = e.ChildText("a[href]")
	})
	c.OnHTML(".primary-featured .full .featured-byline", func(e *colly.HTMLElement) {
		article.ByLine = e.ChildText("em")
	})
	c.OnHTML("div.primary-featured", func(e *colly.HTMLElement) {
		article.Excerpt = e.ChildText("div.featured-excerpt")
		article.Date = e.ChildText("div.featured-date-and-category")
	})
	article.ID = GenerateArticleID(10)
	c.Visit("https://dailynexus.com/")
	_ = CreateArticle(article)
	return GetLatestArticle()
}

const idChars = "1234567890"

func GenerateArticleID(length int) string {
	buffer := make([]byte, length)
	_, err := rand.Read(buffer)
	if err != nil {
		return ""
	}

	otpCharsLength := len(idChars)
	for i := 0; i < length; i++ {
		buffer[i] = idChars[int(buffer[i])%otpCharsLength]
	}

	return string(buffer)
}
