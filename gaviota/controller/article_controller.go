package controller

import (
	"gaviota/service"
	"github.com/gin-gonic/gin"
	"net/http"
)

func GetAllArticles(c *gin.Context) {
	result := service.GetAllArticles()
	c.JSON(http.StatusOK, result)
}

func GetArticleByID(c *gin.Context) {
	result := service.GetArticleByID(c.Param("articleID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No article found with given id: " + c.Param("articleID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func GetLatestArticle(c *gin.Context) {
	result := service.GetLatestArticle()
	c.JSON(http.StatusOK, result)
}
