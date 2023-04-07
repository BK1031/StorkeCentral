package service

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"montecito/config"
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
