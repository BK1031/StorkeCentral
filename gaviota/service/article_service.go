package service

import "gaviota/model"

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
