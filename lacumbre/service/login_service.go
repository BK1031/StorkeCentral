package service

import (
	"lacumbre/model"
)

func GetLoginsForUser(userID string) []model.Login {
	var logins []model.Login
	result := DB.Where("user_id = ?", userID).Find(&logins)
	if result.Error != nil {}
	return logins
}

func GetLoginByID(loginID string) model.Login {
	var request model.Login
	result := DB.Where("id = ?", loginID).Find(&request)
	if result.Error != nil {}
	return request
}

func CreateLogin(login model.Login) error {
	if result := DB.Create(&login); result.Error != nil {
		return result.Error
	}
	return nil
}