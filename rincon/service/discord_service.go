package service

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"rincon/config"
)

var discord *discordgo.Session;

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		fmt.Println("Error creating Discord session, ", err)
		return
	}
	discord = dg
	_, err = discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Rincon v" + config.Version + " online!")
	if err != nil {
		fmt.Println("Error sending Discord message, ", err)
		return
	}
}