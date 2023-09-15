package controller

import (
	"gaviota/config"
	"gaviota/service"
	"gaviota/utils"
	"github.com/gin-gonic/gin"
	cron "github.com/robfig/cron/v3"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"net/http"
	"strconv"
)

func GetAllArticles(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllArticles", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllArticles()
	c.JSON(http.StatusOK, result)
}

func GetArticleByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetArticleByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetArticleByID(c.Param("articleID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No article found with given id: " + c.Param("articleID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func GetLatestArticle(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetLatestArticle", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetLatestArticle()
	c.JSON(http.StatusOK, result)
}

func FetchLatestArticle(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchLatestArticle", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.FetchLatestArticle()
	c.JSON(http.StatusOK, result)
}

func RegisterArticleCronJob() {
	c := cron.New()
	entryID, err := c.AddJob(config.ArticleUpdateCron, func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Article CRON Job")
		utils.SugarLogger.Infoln("Starting Article CRON Job...")
		service.FetchLatestArticle()
		utils.SugarLogger.Infoln("Finished Article CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Fetched latest headlines!")
	})
	if err != nil {
		utils.SugarLogger.Errorln("Failed to register CRON Job: " + err.Error())
	}
	c.Start()
	utils.SugarLogger.Infoln("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.ArticleUpdateCron + "s")
}
