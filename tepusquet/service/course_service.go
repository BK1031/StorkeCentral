package service

import "tepusquet/model"

func GetCoursesForUser(userID string) []model.UserCourse {
	var courses []model.UserCourse
	result := DB.Where("user_id = ?", userID).Find(&model.UserCourse{})
	if result.Error != nil {
	}
	return courses
}

func RemoveCourseForUser(userID string, courseID string) {
	DB.Where("user_id = ? AND course_id = ?", userID, courseID).Delete(&model.UserCourse{})
}

func RemoveAllCoursesForUser(userID string) {
	DB.Where("user_id = ?", userID).Delete(&model.UserCourse{})
}
