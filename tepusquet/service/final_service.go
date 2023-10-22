package service

import (
	"tepusquet/model"
	"tepusquet/utils"
)

func GetAllFinalsForQuarter(quarter string) []model.UserFinal {
	var finals []model.UserFinal
	DB.Where("quarter = ?", quarter).Find(&finals)
	return finals
}

func GetFinalsForUserForQuarter(userID string, quarter string) []model.UserFinal {
	var finals []model.UserFinal
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&finals)
	if result.Error != nil {
	}
	return finals
}

func CreateAllFinalsForUser(finals []model.UserFinal) error {
	if len(finals) > 0 {
		DB.Where("user_id = ? AND quarter = ?", finals[0].UserID, finals[0].Quarter).Delete(&model.UserFinal{})
		for _, final := range finals {
			utils.SugarLogger.Infoln("New final for user " + final.UserID + " for quarter " + final.Quarter)
			if result := DB.Create(&final); result.Error != nil {
				return result.Error
			}
		}
	}
	return nil
}
