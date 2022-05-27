package controller

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/service"
	"net/http"
)

func GetUserLogins(c *gin.Context) {
	result := service.GetLoginsForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func CreateUserLogin(c *gin.Context) {
	var input model.Login
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	user := service.GetUserByID(input.UserID)
	if user.ID != "" {
		println("New user login recorded")
		input.ID = uuid.New().String()
		if err := service.CreateLogin(input); err != nil {
			c.JSON(http.StatusInternalServerError, err)
			return
		}
		service.Discord.ChannelMessageSend(config.DiscordChannel, user.String() + " just logged in from " + input.Agent)
		c.JSON(http.StatusOK, service.GetLoginByID(input.ID))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Failed to find requested user!"})
	}
}
