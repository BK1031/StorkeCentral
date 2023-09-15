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

func GetFriendRequestByID(userID string, friendID string) model.Friend {
	var request model.Friend
	result := DB.Where("from_user_id = ? AND to_user_id = ? OR from_user_id = ? AND to_user_id = ?", userID, friendID, friendID, userID).Find(&request)
	if result.Error != nil {
	}
	request.User = GetUserByID(friendID)
	return request
}

func UpdateFriendRequest(request model.Friend) error {
	if result := DB.Where("from_user_id = ? AND to_user_id = ? OR from_user_id = ? AND to_user_id = ?", request.FromUserID, request.ToUserID, request.ToUserID, request.FromUserID).Updates(&request); result.Error != nil {
		return result.Error
	}
	return nil
}

func CreateFriendRequest(request model.Friend) error {
	if result := DB.Create(&request); result.Error != nil {
		return result.Error
	}
	return nil
}

func DeleteFriendRequest(userID string, friendID string) error {
	if result := DB.Where("from_user_id = ? AND to_user_id = ? OR from_user_id = ? AND to_user_id = ?", userID, friendID, friendID, userID).Delete(&model.Friend{}); result.Error != nil {
		return result.Error
	}
	return nil
}
