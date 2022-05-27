package controller

import (
	"github.com/gin-gonic/gin"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/service"
	"net/http"
)

func GetFriendsForUser(c *gin.Context) {
	result := service.GetFriendsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateFriendRequest(c *gin.Context) {
	var input model.Friend
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	from := service.GetUserByID(input.FromUserID)
	to := service.GetUserByID(input.ToUserID)
	if from.ID != "" && to.ID != "" {
		if service.GetFriendRequestByID(input.ID).ID != "" {
			println("Friend request already exists, updating request in db...")
			if err := service.UpdateFriendRequest(input); err != nil {
				c.JSON(http.StatusInternalServerError, err)
				return
			}
			if input.Status == "ACCEPTED" {
				service.Discord.ChannelMessageSend(config.DiscordChannel, from.String() + " is now friends with " + to.String())
			}
		} else {
			println("Creating new friend request...")
			if err := service.CreateFriendRequest(input); err != nil {
				c.JSON(http.StatusInternalServerError, err)
				return
			}
			service.Discord.ChannelMessageSend(config.DiscordChannel, from.String() + " just sent a friend request to " + to.String())
		}
		c.JSON(http.StatusOK, service.GetFriendRequestByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "One of more of the requested users do not exist!"})
	}
}

func DeleteFriendRequest(c *gin.Context) {
	if err := service.DeleteFriendRequest(c.Param("requestID")); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	} else {
		c.JSON(http.StatusOK, gin.H{"message": "Successfully deleted friendship with given id: " + c.Param("requestID")})
	}
}
