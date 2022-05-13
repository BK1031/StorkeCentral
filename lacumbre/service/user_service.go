package service

import "lacumbre/model"

func GetAllUsers() []model.User {
	var users []model.User
	result := DB.Find(&users)
	if result.Error != nil {}
	return users
}

func GetUserByID(userID string) model.User {
	var user model.User
	result := DB.Where("id = ?", userID).Find(&user)
	if result.Error != nil {}
	return user
}