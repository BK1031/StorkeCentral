package controller

import (
	"github.com/gin-gonic/gin"
	cron "github.com/robfig/cron/v3"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"jalama/config"
	"jalama/service"
	"jalama/utils"
	"net/http"
	"strconv"
	"time"
)

func GetAllMealsForDay(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetAllMealsForDay", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}

func GetMealByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetMealByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetMealByID(c.Param("mealID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No meal record found with given id: " + c.Param("mealID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func GetMenuForMeal(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetMenuForMeal", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetMenuForMeal(c.Param("mealID"))
	c.JSON(http.StatusOK, result)
}

func FetchAllMealsForDay(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchAllMealsForDay", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.FetchAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}

func FetchMenuForMeal(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "FetchMenuForMeal", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	service.FetchMenuForMeal(c.Param("mealID"))
	c.JSON(http.StatusOK, service.GetMenuForMeal(c.Param("mealID")))
}

func RegisterMealCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc(config.MealUpdateCron, func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Meal CRON Job")
		utils.SugarLogger.Infoln("Starting Meal CRON Job...")
		days, _ := strconv.Atoi(config.MealUpdateDays)
		for i := 0; i <= days; i++ {
			queryDate := time.Now().AddDate(0, 0, i).Format("01-02-2006")
			utils.SugarLogger.Infoln("Fetching meals for day: " + queryDate)
			service.FetchAllMealsForDay(queryDate)
		}
		utils.SugarLogger.Infoln("Finished Meal CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Fetched latest meals (today + next "+config.MealUpdateDays+"days)!")
	})
	if err != nil {
		return
	}
	c.Start()
	utils.SugarLogger.Infoln("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled with cron expression: " + config.MealUpdateCron)
}
