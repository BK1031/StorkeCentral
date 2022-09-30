package service

import "lacumbre/model"

func GetFriendsForUser(userID string) []model.Friend {
	var friends []model.Friend
	result := DB.Where("from_user_id = ? OR to_user_id = ?", userID, userID).Find(&friends)
	if result.Error != nil {
	}
	for i := range friends {
		if friends[i].FromUserID == userID {
			friends[i].User = GetUserByID(friends[i].ToUserID)
		} else {
			friends[i].User = GetUserByID(friends[i].FromUserID)
		}
	}
	return friends
}

func GetFriendRequestByID(requestID string) model.Friend {
	var request model.Friend
	result := DB.Where("id = ?", requestID).Find(&request)
	if result.Error != nil {
	}
	return request
}

func UpdateFriendRequest(request model.Friend) error {
	if result := DB.Where("id = ?", request.ID).Updates(&request); result.Error != nil {
		return result.Error
	}
	return nil
}

func CreateFriendRequest(request model.Friend) error {
	request.ID = request.FromUserID + "-" + request.ToUserID
	if result := DB.Create(&request); result.Error != nil {
		return result.Error
	}
	return nil
}

func DeleteFriendRequest(requestID string) error {
	if result := DB.Where("id = ?", requestID).Delete(&model.Friend{}); result.Error != nil {
		return result.Error
	}
	return nil
}
