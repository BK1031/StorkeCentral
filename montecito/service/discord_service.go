package service

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"github.com/gin-gonic/gin"
	"montecito/config"
	"strconv"
	"time"
)

var Discord *discordgo.Session

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		fmt.Println("Error creating Discord session, ", err)
		return
	}
	Discord = dg
	_, err = Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Montecito v"+config.Version+" online! `[ENV = "+config.Env+"]`")
	if err != nil {
		fmt.Println("Error sending Discord message, ", err)
		return
	}
}

func DiscordLogRequest(c *gin.Context) {
	requestID := c.GetHeader("Request-ID")
	if c.Writer.Status() >= 200 && c.Writer.Status() < 300 {
		_, err := Discord.ChannelMessageSend(config.DiscordChannel, ":green_circle: `STATUS "+strconv.Itoa(c.Writer.Status())+"`\n"+
			"```Request ID: "+requestID+"\n\n"+
			time.Now().Format("Mon Jan 02 15:04:05 MST 2006")+"\n"+
			"["+c.Request.Method+"] "+c.Request.Host+c.Request.URL.String()+
			"\nUser \"userID\" [user@ucsb.edu]```")
		if err != nil {
			fmt.Println("Error sending Discord message, ", err)
			return
		}
	} else {
		_, err := Discord.ChannelMessageSend(config.DiscordChannel, ":red_circle: `STATUS "+strconv.Itoa(c.Writer.Status())+"`\n"+
			"```Request ID: "+requestID+"\n\n"+
			time.Now().Format("Mon Jan 02 15:04:05 MST 2006")+"\n"+
			"["+c.Request.Method+"] "+c.Request.Host+c.Request.URL.String()+
			"\nUser \"userID\" [user@ucsb.edu]```")
		if err != nil {
			fmt.Println("Error sending Discord message, ", err)
			return
		}
	}
}
