package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/service"
	"lacumbre/utils"
	"net/http"
)

func GetFriendsForUser(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetFriendsForUser", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetFriendsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateFriendRequest(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateFriendRequest", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	var input model.Friend
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	from := service.GetUserByID(input.FromUserID)
	to := service.GetUserByID(input.ToUserID)
	if from.ID != "" && to.ID != "" {
		if service.GetFriendRequestByID(input.ID).ID != "" {
			utils.SugarLogger.Errorln("Friend request already exists, updating request in db...")
			if err := service.UpdateFriendRequest(input); err != nil {
				c.JSON(http.StatusInternalServerError, err)
				return
			}
			if input.Status == "ACCEPTED" {
				go service.Discord.ChannelMessageSend(config.DiscordChannel, from.String()+" is now friends with "+to.String())
				notification := service.MirandaNotification{
					ID:         uuid.New().String(),
					UserID:     from.ID,
					Sender:     config.Service.Name,
					Title:      "Friend request accepted!",
					Body:       to.FirstName + " accepted your friend request!",
					PictureUrl: to.ProfilePictureURL,
					LaunchUrl:  "",
					Route:      "/profile/user/" + to.ID,
					Priority:   "HIGH",
					Push:       true,
					Read:       false,
				}
				go service.SendMirandaNotification(notification, c.GetHeader("Request-ID"), "")
			}
		} else {
			utils.SugarLogger.Errorln("Creating new friend request...")
			if err := service.CreateFriendRequest(input); err != nil {
				c.JSON(http.StatusInternalServerError, err)
				return
			}
			go service.Discord.ChannelMessageSend(config.DiscordChannel, from.String()+" just sent a friend request to "+to.String())
			notification := service.MirandaNotification{
				ID:         uuid.New().String(),
				UserID:     to.ID,
				Sender:     config.Service.Name,
				Title:      "New friend request!",
				Body:       from.FirstName + " just sent you a friend request!",
				PictureUrl: from.ProfilePictureURL,
				LaunchUrl:  "",
				Route:      "/profile/user/" + from.ID,
				Priority:   "HIGH",
				Push:       true,
				Read:       false,
			}
			go service.SendMirandaNotification(notification, c.GetHeader("Request-ID"), "")
		}
		c.JSON(http.StatusOK, service.GetFriendRequestByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "One or more of the requested users do not exist!"})
	}
}

func DeleteFriendRequest(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "DeleteFriendRequest", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	if err := service.DeleteFriendRequest(c.Param("requestID")); err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	} else {
		c.JSON(http.StatusOK, gin.H{"message": "Successfully deleted friendship with given id: " + c.Param("requestID")})
	}
}
