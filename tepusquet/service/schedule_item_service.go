package service

import "tepusquet/model"

func GetScheduleForUserForQuarter(userID string, quarter string) []model.UserScheduleItem {
	var schedule []model.UserScheduleItem
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&schedule)
	if result.Error != nil {
	}
	return schedule
}

func SetScheduleForUserForQuarter(scheduleItems []model.UserScheduleItem) error {
	for _, s := range scheduleItems {
		if result := DB.Create(&s); result.Error != nil {
			return result.Error
		}
	}
	return nil
}

func RemoveScheduleForUserForQuarter(userID string, quarter string) {
	DB.Where("user_id = ? AND quarter = ?", userID, quarter).Delete(&model.UserScheduleItem{})
}
