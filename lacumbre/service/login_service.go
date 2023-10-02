package service

import (
	"lacumbre/model"
	"lacumbre/utils"
	"strconv"
	"time"
)

func GetAllLogins() []model.Login {
	var logins []model.Login
	result := DB.Order("created_at DESC").Find(&logins)
	if result.Error != nil {
	}
	return logins
}

func GetLoginsForLastNDays(days string) []model.Login {
	var logins []model.Login
	dayInt, err := strconv.Atoi(days)
	if err != nil {
		utils.SugarLogger.Errorln("error converting days to int: ", err.Error())
	}
	result := DB.Where("created_at >= ?", time.Now().AddDate(0, 0, -dayInt)).Order("created_at DESC").Find(&logins)
	if result.Error != nil {
	}
	return logins
}

func GetLoginsForUser(userID string) []model.Login {
	var logins []model.Login
	result := DB.Where("user_id = ?", userID).Order("created_at DESC").Find(&logins)
	if result.Error != nil {
	}
	return logins
}

func GetLoginsForUserLastNDays(userID string, days string) []model.Login {
	var logins []model.Login
	dayInt, err := strconv.Atoi(days)
	if err != nil {
		utils.SugarLogger.Errorln("error converting days to int: ", err.Error())
	}
	result := DB.Where("user_id = ? AND created_at >= ?", userID, time.Now().AddDate(0, 0, -dayInt)).Order("created_at DESC").Find(&logins)
	if result.Error != nil {
	}
	return logins
}

func GetLoginByID(loginID string) model.Login {
	var request model.Login
	result := DB.Where("id = ?", loginID).Find(&request)
	if result.Error != nil {
	}
	return request
}

func CreateLogin(login model.Login) error {
	if result := DB.Create(&login); result.Error != nil {
		return result.Error
	}
	return nil
}
