package main

import (
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/controller"
	"jalama/model"
	"jalama/service"
	"strconv"
	"strings"
	"time"
)

var router *gin.Engine

func setupRouter() *gin.Engine {
	if config.Env == "PROD" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(controller.RequestLogger())
	r.Use(controller.AuthChecker())
	return r
}

func main() {
	router = setupRouter()
	service.InitializeDB()
	service.InitializeFirebase()
	service.ConnectDiscord()
	service.RegisterRincon()
	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}

func fetchDining() {
	client := resty.New()
	resp, err := client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/commons/v1/")
	fmt.Println("Response Info:")
	fmt.Println("  Error      :", err)
	fmt.Println("  Status Code:", resp.StatusCode())
	fmt.Println("  Time       :", resp.Time())
	fmt.Println()

	var result []map[string]interface{}
	json.Unmarshal(resp.Body(), &result)
	var diningHalls []model.DiningHall
	for _, hall := range result {
		diningHalls = append(diningHalls, model.DiningHall{
			ID:             hall["code"].(string),
			Name:           hall["name"].(string),
			HasSackMeal:    hall["hasSackMeal"].(bool),
			HasTakeoutMeal: hall["hasTakeOutMeal"].(bool),
			HasDiningCam:   hall["hasDiningCam"].(bool),
			Latitude:       hall["location"].(map[string]interface{})["latitude"].(float64),
			Longitude:      hall["location"].(map[string]interface{})["longitude"].(float64),
		})
	}

	resp, err = client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/commons/v1/hours/3-9-23")
	fmt.Println("Response Info:")
	fmt.Println("  Error      :", err)
	fmt.Println("  Status Code:", resp.StatusCode())
	fmt.Println("  Time       :", resp.Time())
	fmt.Println()

	json.Unmarshal(resp.Body(), &result)
	var meals []model.Meal
	for _, meal := range result {
		// PST current date without time
		t := time.Now()
		currentTime := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
		//fmt.Println(currentTime)
		if meal["open"] != nil {
			openTime := meal["open"].(string)
			openTimeSegments := strings.Split(openTime, " ")
			ampm := openTimeSegments[1]
			openTimeSegments = strings.Split(openTimeSegments[0], ":")
			hour, _ := strconv.ParseInt(openTimeSegments[0], 10, 16)
			minute, _ := strconv.ParseInt(openTimeSegments[1], 10, 16)
			if ampm == "PM" {
				hour += 12
			}
			openDate := currentTime.Add(time.Hour*time.Duration(hour) + time.Minute*time.Duration(minute))
			//fmt.Println("Open: " + openDate.String())

			closeTime := meal["close"].(string)
			closeTimeSegments := strings.Split(closeTime, " ")
			ampm = closeTimeSegments[1]
			closeTimeSegments = strings.Split(closeTimeSegments[0], ":")
			hour, _ = strconv.ParseInt(closeTimeSegments[0], 10, 16)
			minute, _ = strconv.ParseInt(closeTimeSegments[1], 10, 16)
			if ampm == "PM" {
				hour += 12
			}
			closeDate := currentTime.Add(time.Hour*time.Duration(hour) + time.Minute*time.Duration(minute))
			//fmt.Println("Close: " + closeDate.String())

			meals = append(meals, model.Meal{
				ID:           meal["diningCommonCode"].(string) + "-" + meal["mealCode"].(string) + "-" + meal["date"].(string),
				Name:         meal["mealCode"].(string),
				DiningHallID: meal["diningCommonCode"].(string),
				Open:         openDate.UTC(),
				Close:        closeDate.UTC(),
			})
		}
	}

	for _, m := range meals {
		queryDate := m.Open.Local().Format("2006-01-02")
		resp, err = client.R().
			EnableTrace().
			SetHeader("ucsb-api-key", config.UcsbApiKey).
			Get("https://api.ucsb.edu/dining/menu/v1/" + queryDate + "/" + m.DiningHallID + "/" + m.Name)
		fmt.Println("Response Info:")
		fmt.Println("  Error      :", err)
		fmt.Println("  Status Code:", resp.StatusCode())
		fmt.Println("  Time       :", resp.Time())
		fmt.Println()

		json.Unmarshal(resp.Body(), &result)
		for _, item := range result {
			m.MenuItems = append(m.MenuItems, model.MenuItem{
				MealID:  m.ID,
				Name:    item["name"].(string),
				Station: item["station"].(string),
			})
			//fmt.Println(m.MenuItems[len(m.MenuItems)-1])
		}
		fmt.Println(m.MenuItems)
	}

	fmt.Println(meals)
	fmt.Println(meals[1].MenuItems)
}
