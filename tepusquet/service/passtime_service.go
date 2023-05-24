package service

import "tepusquet/model"

func GetAllPasstimesForQuarter(quarter string) []model.UserPasstime {
	var passtimes []model.UserPasstime
	DB.Where("quarter = ?", quarter).Find(&passtimes)
	return passtimes
}

func GetPasstimeForUserForQuarter(userID string, quarter string) model.UserPasstime {
	var passtime model.UserPasstime
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&passtime)
	if result.Error != nil {
	}
	return passtime
}

func CreatePasstimeForUser(passtime model.UserPasstime) error {
	if DB.Where("user_id = ? AND quarter = ?", passtime.UserID, passtime.Quarter).Updates(&passtime).RowsAffected == 0 {
		println("New passtime for user " + passtime.UserID + " for quarter " + passtime.Quarter)
		if result := DB.Create(&passtime); result.Error != nil {
			return result.Error
		}
	} else {
		println("Passtime for user " + passtime.UserID + " for quarter " + passtime.Quarter + " has been updated!")
	}
	return nil
}
