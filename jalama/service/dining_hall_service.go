package service

import (
	"encoding/json"
	"fmt"
	"github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/model"
)

func GetAllDiningHalls() []model.DiningHall {
	var diningHalls []model.DiningHall
	result := DB.Find(&diningHalls)
	if result.Error != nil {
	}
	return diningHalls
}

func GetDiningHall(diningHallID string) model.DiningHall {
	var diningHall model.DiningHall
	result := DB.Where("id = ?", diningHallID).First(&diningHall)
	if result.Error != nil {
	}
	return diningHall
}

func FetchAllDiningHalls() []model.DiningHall {
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

	var responseMap []map[string]interface{}
	json.Unmarshal(resp.Body(), &responseMap)
	for _, hall := range responseMap {
		hall := model.DiningHall{
			ID:             hall["code"].(string),
			Name:           hall["name"].(string),
			HasSackMeal:    hall["hasSackMeal"].(bool),
			HasTakeoutMeal: hall["hasTakeOutMeal"].(bool),
			HasDiningCam:   hall["hasDiningCam"].(bool),
			Latitude:       hall["location"].(map[string]interface{})["latitude"].(float64),
			Longitude:      hall["location"].(map[string]interface{})["longitude"].(float64),
		}
		// Save dining hall to database
		if DB.Where("id = ?", hall.ID).Updates(&hall).RowsAffected == 0 {
			if result := DB.Create(&hall); result.Error != nil {
			}
		}
	}
	return GetAllDiningHalls()
}
