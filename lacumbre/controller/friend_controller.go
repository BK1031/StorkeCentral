package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"lacumbre/config"
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

func GetFriendRequestByID(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "GetFriendRequestByID", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	result := service.GetFriendRequestByID(c.Param("userID"), c.Param("friendID"))
	if result.FromUserID != "" {
		c.JSON(http.StatusOK, result)
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Friend request not found!"})
	}
}

func CreateFriendRequest(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "CreateFriendRequest", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	toUserID := c.Param("friendID")
	fromUserID := c.Param("userID")
	request := service.GetFriendRequestByID(fromUserID, toUserID)
	if request.FromUserID != "" {
		// Friend request already exists
		c.JSON(http.StatusConflict, gin.H{"message": "Friend request already exists!"})
		return
	} else {
		from := service.GetUserByID(fromUserID)
		to := service.GetUserByID(toUserID)
		if from.ID == "" {
			c.JSON(http.StatusNotFound, gin.H{"message": "User with id " + fromUserID + " not found!"})
			return
		} else if to.ID == "" {
			c.JSON(http.StatusNotFound, gin.H{"message": "User with id " + toUserID + " not found!"})
			return
		} else {
			request.FromUserID = fromUserID
			request.ToUserID = toUserID
			request.Status = "REQUESTED"
			utils.SugarLogger.Errorln("Creating new friend request...")
			if err := service.CreateFriendRequest(request); err != nil {
				utils.SugarLogger.Errorln("Failed to create friend request: " + err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
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
			c.JSON(http.StatusOK, service.GetFriendRequestByID(fromUserID, toUserID))
		}
	}
}

func AcceptFriendRequest(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "AcceptFriendRequest", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	toUserID := c.Param("friendID")
	fromUserID := c.Param("userID")
	request := service.GetFriendRequestByID(fromUserID, toUserID)
	if request.FromUserID != "" {
		// Friend request already exists
		request.Status = "ACCEPTED"
		if err := service.UpdateFriendRequest(request); err != nil {
			utils.SugarLogger.Errorln("Failed to update friend request: " + err.Error())
			c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
			return
		}
		from := service.GetUserByID(fromUserID)
		to := service.GetUserByID(toUserID)
		go service.Discord.ChannelMessageSend(config.DiscordChannel, from.String()+" just sent a friend request to "+to.String())
		notification := service.MirandaNotification{
			ID:         uuid.New().String(),
			UserID:     from.ID,
			Sender:     config.Service.Name,
			Title:      "Friend request accepted!",
			Body:       to.FirstName + " just accepted your friend request!",
			PictureUrl: to.ProfilePictureURL,
			LaunchUrl:  "",
			Route:      "/profile/user/" + to.ID,
			Priority:   "HIGH",
			Push:       true,
			Read:       false,
		}
		go service.SendMirandaNotification(notification, c.GetHeader("Request-ID"), "")
		c.JSON(http.StatusOK, service.GetFriendRequestByID(fromUserID, toUserID))
	} else {
		c.JSON(http.StatusConflict, gin.H{"message": "Friend request doesn't exist!"})
		return
	}
}

func DeleteFriendRequest(c *gin.Context) {
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "DeleteFriendRequest", oteltrace.WithAttributes(attribute.Key("Request-ID").String(c.GetHeader("Request-ID"))))
	defer span.End()

	if err := service.DeleteFriendRequest(c.Param("userID"), c.Param("friendID")); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	} else {
		c.JSON(http.StatusOK, gin.H{"message": "Successfully deleted friendship"})
	}
}
