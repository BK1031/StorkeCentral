package service

import (
	"gaviota/model"
	"gaviota/utils"
	colly "github.com/gocolly/colly/v2"
	"github.com/google/uuid"
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
		utils.SugarLogger.Infoln("New article created with id: " + article.ID)
		if result := DB.Create(&article); result.Error != nil {
			return result.Error
		}
		go DiscordLogNewArticle(article)
	} else {
		utils.SugarLogger.Infoln("Article with id: " + article.ID + " has been updated!")
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
	article.ID = uuid.New().String()
	c.Visit("https://dailynexus.com/")
	if article.Title == GetLatestArticle().Title {
		utils.SugarLogger.Infoln("No new headlines, latest is still: \"" + article.Title + "\"")
		return article
	}
	_ = CreateArticle(article)
	return GetLatestArticle()
}
