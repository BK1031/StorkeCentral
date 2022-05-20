package service

import "lacumbre/model"

func GetAllUsers() []model.User {
	var users []model.User
	result := DB.Find(&users)
	if result.Error != nil {}
	for _, user := range users {
		user.Privacy = GetPrivacyForUser(user.ID)
	}
	return users
}

func GetUserByID(userID string) model.User {
	var user model.User
	result := DB.Where("id = ?", userID).Find(&user)
	if result.Error != nil {}
	return user
}

func CreateUser(user model.User) error {
	if DB.Where("id = ?", user.ID).Updates(&user).RowsAffected == 0 {
		if result := DB.Create(&user); result.Error != nil {
			return result.Error
		}
	}
	if user.Privacy.UserID != "" {
		if err := SetPrivacyForUser(user.ID, user.Privacy); err != nil {
			return err
		}
	}
	return nil
}