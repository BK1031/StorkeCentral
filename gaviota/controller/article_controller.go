package controller

import (
	"gaviota/config"
	"gaviota/service"
	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
	"net/http"
	"strconv"
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

func FetchLatestArticle(c *gin.Context) {
	result := service.FetchLatestArticle()
	c.JSON(http.StatusOK, result)
}

func RegisterArticleCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc("@every "+config.ArticleUpdateDelay+"s", func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Article CRON Job")
		println("Starting Article CRON Job...")
		service.FetchLatestArticle()
		println("Finished Article CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Fetched latest headlines!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.ArticleUpdateDelay + "s")
}
