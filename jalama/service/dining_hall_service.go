package service

import (
	"encoding/json"
	resty "github.com/go-resty/resty/v2"
	"jalama/config"
	"jalama/model"
	"jalama/utils"
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
	utils.SugarLogger.Infoln("Response Info:")
	utils.SugarLogger.Infoln("  Error      :", err)
	utils.SugarLogger.Infoln("  Status Code:", resp.StatusCode())
	utils.SugarLogger.Infoln("  Time       :", resp.Time())

	var responseMap []map[string]interface{}
	json.Unmarshal(resp.Body(), &responseMap)
	for _, hall := range responseMap {
		diningHall := model.DiningHall{
			ID:             hall["code"].(string),
			Name:           hall["name"].(string),
			HasSackMeal:    hall["hasSackMeal"].(bool),
			HasTakeoutMeal: hall["hasTakeOutMeal"].(bool),
			HasDiningCam:   hall["hasDiningCam"].(bool),
			Latitude:       hall["location"].(map[string]interface{})["latitude"].(float64),
			Longitude:      hall["location"].(map[string]interface{})["longitude"].(float64),
		}
		// Save dining hall to database
		if DB.Where("id = ?", diningHall.ID).Updates(&diningHall).RowsAffected == 0 {
			if result := DB.Create(&diningHall); result.Error != nil {
			}
		}
	}
	return GetAllDiningHalls()
}
