package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
	"jalama/config"
	"jalama/service"
	"net/http"
	"strconv"
	"time"
)

func GetAllMealsForDay(c *gin.Context) {
	result := service.GetAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}

func GetMealByID(c *gin.Context) {
	result := service.GetMealByID(c.Param("mealID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No meal record found with given id: " + c.Param("mealID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func GetMenuForMeal(c *gin.Context) {
	result := service.GetMenuForMeal(c.Param("mealID"))
	c.JSON(http.StatusOK, result)
}

func FetchAllMealsForDay(c *gin.Context) {
	result := service.FetchAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}

func RegisterMealCronJob() {
	c := cron.New()
	entryID, err := c.AddFunc("@every "+config.MealUpdateDelay+"s", func() {
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":alarm_clock: Starting Meal CRON Job")
		println("Starting Meal CRON Job...")
		service.FetchAllMealsForDay(time.Now().Format("2006-01-02"))
		service.FetchAllMealsForDay(time.Now().AddDate(0, 0, 1).Format("2006-01-02"))
		println("Finished Meal CRON Job!")
		_, _ = service.Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Fetched latest meals (today + tomorrow)!")
	})
	if err != nil {
		return
	}
	c.Start()
	println("Registered CRON Job: " + strconv.Itoa(int(entryID)) + " scheduled for every " + config.MealUpdateDelay + "s")
}
