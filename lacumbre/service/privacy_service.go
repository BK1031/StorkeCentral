package service

import "lacumbre/model"

func GetPrivacyForUser(userID string) model.Privacy {
	var privacy model.Privacy
	result := DB.Where("user_id = ?", userID).Find(&privacy)
	if result.Error != nil {}
	return privacy
}

func SetPrivacyForUser(userID string, privacy model.Privacy) error {
	if DB.Where("user_id = ?", userID).Updates(&privacy).RowsAffected == 0 {
		println("New privacy settings created for user with id: " + userID)
		if result := DB.Create(&privacy); result.Error != nil {
			return result.Error
		}
	} else {
		println("Existing privacy settings updated for user with id: " + userID)
	}
	return nil
}
