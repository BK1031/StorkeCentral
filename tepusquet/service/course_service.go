package service

import "tepusquet/model"

func GetAllCoursesForUser(userID string) []model.UserCourse {
	var courses []model.UserCourse
	result := DB.Where("user_id = ?", userID).Find(&courses)
	if result.Error != nil {
	}
	return courses
}

func GetCoursesForUserForQuarter(userID string, quarter string) []model.UserCourse {
	var courses []model.UserCourse
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&courses)
	if result.Error != nil {
	}
	return courses
}

func AddCourseForUser(course model.UserCourse) error {
	if result := DB.Create(&course); result.Error != nil {
		return result.Error
	}
	DiscordLogNewCourse(course)
	return nil
}

func RemoveCourseForUserForQuarter(userID string, courseID string, quarter string) {
	DB.Where("user_id = ? AND course_id = ? AND quarter = ?", userID, courseID, quarter).Delete(&model.UserCourse{})
}

func RemoveAllCoursesForUserForQuarter(userID string, quarter string) {
	DB.Where("user_id = ? AND quarter = ?", userID, quarter).Delete(&model.UserCourse{})
}
