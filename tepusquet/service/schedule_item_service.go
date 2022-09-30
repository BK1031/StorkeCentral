package service

import "tepusquet/model"

func GetScheduleForUserForQuarter(userID string, quarter string) []model.UserScheduleItem {
	var schedule []model.UserScheduleItem
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&schedule)
	if result.Error != nil {
	}
	return schedule
}

func AddScheduleItemForUserForQuarter(scheduleItem model.UserScheduleItem) error {
	if DB.Where("user_id = ? AND quarter = ? AND course_id = ?", scheduleItem.UserID, scheduleItem.Quarter, scheduleItem.CourseID).Updates(&scheduleItem).RowsAffected == 0 {
		println("New schedule item created for user " + scheduleItem.UserID + " for quarter " + scheduleItem.Quarter + " for course " + scheduleItem.CourseID)
		if result := DB.Create(&scheduleItem); result.Error != nil {
			return result.Error
		}
	} else {
		println("Schedule item updated for user " + scheduleItem.UserID + " for quarter " + scheduleItem.Quarter + " for course " + scheduleItem.CourseID)
	}
	return nil
}

func RemoveScheduleForUserForQuarter(userID string, quarter string) {
	DB.Where("user_id = ? AND quarter = ?", userID, quarter).Delete(&model.UserScheduleItem{})
}
