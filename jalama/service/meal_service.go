package service

import (
	"encoding/json"
	resty "github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/model"
	"jalama/utils"
	"strconv"
	"strings"
	"time"
)

func GetAllMealsForDay(date string) []model.Meal {
	var meals []model.Meal
	result := DB.Where("id LIKE ?", "%"+date).Find(&meals)
	if result.Error != nil {
	}
	for i := range meals {
		meals[i].MenuItems = GetMenuForMeal(meals[i].ID)
	}
	return meals
}

func GetMealByID(mealID string) model.Meal {
	var meal model.Meal
	result := DB.Where("id = ?", mealID).First(&meal)
	meal.MenuItems = GetMenuForMeal(mealID)
	if result.Error != nil {
	}
	return meal
}

func GetMenuForMeal(mealID string) []model.MenuItem {
	var menuItems []model.MenuItem
	result := DB.Where("meal_id = ?", mealID).Find(&menuItems)
	if result.Error != nil {
	}
	return menuItems
}

func FetchAllMealsForDay(date string) []model.Meal {
	// date will be in the format of "MM-DD-YYYY"
	// PST input date without time
	t := time.Now()
	dateSlice := strings.Split(date, "-")
	month, _ := strconv.Atoi(dateSlice[0])
	day, _ := strconv.Atoi(dateSlice[1])
	year, _ := strconv.Atoi(dateSlice[2])
	currentTime := time.Date(year, time.Month(month), day, 0, 0, 0, 0, t.Location())

	client := resty.New()
	resp, err := client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/commons/v1/hours/" + date)
	utils.SugarLogger.Infoln("Response Info:")
	utils.SugarLogger.Infoln("  Error      :", err)
	utils.SugarLogger.Infoln("  Status Code:", resp.StatusCode())
	utils.SugarLogger.Infoln("  Time       :", resp.Time())

	var responseMap []map[string]interface{}
	json.Unmarshal(resp.Body(), &responseMap)
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
			//openDateUTC := openDate.UTC()

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
			//closeDateUTC := closeDate.UTC()

			diningMeal := model.Meal{
				ID:           meal["diningCommonCode"].(string) + "-" + meal["mealCode"].(string) + "-" + currentTime.Format("01-02-2006"),
				Name:         meal["mealCode"].(string),
				DiningHallID: meal["diningCommonCode"].(string),
				Open:         openDate,
				Close:        closeDate,
			}
			// Save dining meal to database
			if DB.Where("id = ?", diningMeal.ID).Updates(&diningMeal).RowsAffected == 0 {
				if result := DB.Create(&diningMeal); result.Error != nil {
				}
			}
			FetchMenuForMeal(diningMeal.ID)
		}
	}
	return GetAllMealsForDay(date)
}

func FetchMenuForMeal(mealID string) {
	meal := GetMealByID(mealID)
	queryDate := strings.Split(mealID, meal.Name+"-")[1]

	client := resty.New()
	resp, err := client.R().
		EnableTrace().
		SetHeader("ucsb-api-key", config.UcsbApiKey).
		Get("https://api.ucsb.edu/dining/menu/v1/" + queryDate + "/" + meal.DiningHallID + "/" + meal.Name)
	utils.SugarLogger.Infoln("Response Info:")
	utils.SugarLogger.Infoln("  Error      :", err)
	utils.SugarLogger.Infoln("  Status Code:", resp.StatusCode())
	utils.SugarLogger.Infoln("  Time       :", resp.Time())

	var responseMap []map[string]interface{}
	json.Unmarshal(resp.Body(), &responseMap)
	for _, item := range responseMap {
		menuItem := model.MenuItem{
			MealID:  meal.ID,
			Name:    item["name"].(string),
			Station: item["station"].(string),
		}
		// Save meal item to database
		if DB.Where("meal_id = ? AND name = ?", menuItem.MealID, menuItem.Name).Updates(&menuItem).RowsAffected == 0 {
			if result := DB.Create(&menuItem); result.Error != nil {
			}
		}
		meal.MenuItems = append(meal.MenuItems, menuItem)
	}
	DiscordLogNewMeal(meal)
}
