package service

import (
	"github.com/bwmarrin/discordgo"
	"rincon/config"
	"rincon/utils"
)

var Discord *discordgo.Session

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		utils.SugarLogger.Errorln("Error creating Discord session, ", err)
		return
	}
	Discord = dg
	_, err = Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Rincon v"+config.Version+" online! `[ENV = "+config.Env+"]`")
	if err != nil {
		utils.SugarLogger.Errorln("Error sending Discord message, ", err)
		return
	}
}
