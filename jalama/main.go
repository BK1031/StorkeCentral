package main

import (
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	resty "github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/controller"
	"jalama/model"
	"jalama/service"
	"jalama/utils"
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
	r.Use(utils.JaegerPropogator())
	r.Use(controller.AuthChecker())
	return r
}

func main() {
	utils.InitializeLogger()
	defer utils.Logger.Sync()

	router = setupRouter()
	service.InitializeDB()
	service.RegisterRincon()
	service.InitializeFirebase()
	service.ConnectDiscord()
	controller.RegisterMealCronJob()
	utils.InitializeJaeger()

	controller.InitializeRoutes(router)
	router.Run(":" + config.Port)
}

// Testing function for pulling dining hall data, meal timings, menu items
func fetchDining() {
	queryDate := "09-15-2023"
	fmt.Println("============ Fetching dining halls ============")
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
	for _, hall := range diningHalls {
		fmt.Println(hall.ID + " - " + hall.Name)
	}
	fmt.Println("Found " + strconv.Itoa(len(diningHalls)) + " dining halls")
	fmt.Println("============ Fetching dining hours ============")
	resp, err = client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/commons/v1/hours/" + queryDate)
	fmt.Println("Response Info:")
	fmt.Println("  Error      :", err)
	fmt.Println("  Status Code:", resp.StatusCode())
	fmt.Println("  Time       :", resp.Time())
	fmt.Println()

	json.Unmarshal(resp.Body(), &result)
	var meals []model.Meal
	for _, meal := range result {
		// PT current date without time
		t := time.Now()
		year, _ := strconv.ParseInt(strings.Split(queryDate, "-")[2], 10, 16)
		month, _ := strconv.ParseInt(strings.Split(queryDate, "-")[0], 10, 16)
		day, _ := strconv.ParseInt(strings.Split(queryDate, "-")[1], 10, 16)
		currentTime := time.Date(int(year), time.Month(int(month)), int(day), 0, 0, 0, 0, t.Location())
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

			meals = append(meals, model.Meal{
				ID:           meal["diningCommonCode"].(string) + "-" + meal["mealCode"].(string) + "-" + strconv.Itoa(int(month)) + "-" + strconv.Itoa(int(day)) + "-" + strconv.Itoa(int(year)),
				Name:         meal["mealCode"].(string),
				DiningHallID: meal["diningCommonCode"].(string),
				Open:         openDate.UTC(),
				Close:        closeDate.UTC(),
			})
		}
	}
	for _, meal := range meals {
		fmt.Println(meal.ID + " - " + meal.Name + "\nOpen: " + meal.Open.Local().String() + "\nClose: " + meal.Close.Local().String() + "\n")
	}
	fmt.Println("Found " + strconv.Itoa(len(meals)) + " meals")

	for _, m := range meals {
		fmt.Println("============ Fetching menu items for " + m.ID + " ============")
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
		}
		for _, item := range m.MenuItems {
			fmt.Println(item.Station + " - " + item.Name)
		}
		fmt.Println("Found " + strconv.Itoa(len(m.MenuItems)) + " menu items")
	}
}
