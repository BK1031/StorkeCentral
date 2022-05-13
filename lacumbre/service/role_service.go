package service

import (
	"lacumbre/model"
)

func GetRolesForUser(userID string) []model.Role {
	var roles []model.Role
	result := DB.Where("user_id = ?", userID).Find(&roles)
	if result.Error != nil {}
	return roles
}

func SetRolesForUser(userID string, roles []model.Role) error {
	DB.Where("user_id = ?", userID).Delete(&model.Role{})
	for _, r := range roles {
		if result := DB.Create(&r); result.Error != nil {
			return result.Error
		}
	}
	return nil
}