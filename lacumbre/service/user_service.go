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
		println("New user created with id: " + user.ID)
		if result := DB.Create(&user); result.Error != nil {
			return result.Error
		}
	} else {
		println("User with id: " + user.ID + " has been updated!")
	}
	if user.Privacy.UserID != "" {
		println("User with id: " + user.ID + " has non-empty privacy object, setting privacy in db...")
		if err := SetPrivacyForUser(user.ID, user.Privacy); err != nil {
			return err
		}
	} else {
		println("User with id: " + user.ID + " has empty privacy object, nothing to do here!")
	}
	return nil
}