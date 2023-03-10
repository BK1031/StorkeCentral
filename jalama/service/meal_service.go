package service

import (
	"encoding/json"
	"fmt"
	"github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/model"
	"strconv"
	"strings"
	"time"
)

func FetchAllMealsForDay(date string) []model.Meal {
	// date will be in the format of "M-D-YYYY"
	// PST input date without time
	t := time.Now()
	dateSlice := strings.Split(date, "-")
	month, _ := strconv.Atoi(dateSlice[0])
	day, _ := strconv.Atoi(dateSlice[1])
	year, _ := strconv.Atoi(dateSlice[2])
	currentTime := time.Date(year, time.Month(month), day, 0, 0, 0, 0, t.Location())
	fmt.Println(currentTime)

	client := resty.New()
	resp, err := client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/commons/v1/hours/" + date)
	fmt.Println("Response Info:")
	fmt.Println("  Error      :", err)
	fmt.Println("  Status Code:", resp.StatusCode())
	fmt.Println("  Time       :", resp.Time())
	fmt.Println()

	var responseMap []map[string]interface{}
	json.Unmarshal(resp.Body(), &responseMap)
	var meals []model.Meal
	for _, meal := range responseMap {
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
	return meals
}
