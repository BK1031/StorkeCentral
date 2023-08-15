package service

import (
	"github.com/bwmarrin/discordgo"
	"jalama/config"
	"jalama/model"
	"jalama/utils"
	"strconv"
)

var Discord *discordgo.Session

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		utils.SugarLogger.Errorln("Error creating Discord session, ", err)
		return
	}
	Discord = dg
	_, err = Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: "+config.Service.Name+" v"+config.Version+" online! `[ENV = "+config.Env+"]`")
	if err != nil {
		utils.SugarLogger.Errorln("Error sending Discord message, ", err)
		return
	}
}

func DiscordLogNewMeal(meal model.Meal) {
	var embeds []*discordgo.MessageEmbed
	var fields []*discordgo.MessageEmbedField
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Dining Hall",
		Value:  meal.DiningHallID,
		Inline: false,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Time",
		Value:  meal.Open.Local().Format("3:04 PM") + " - " + meal.Close.Local().Format("3:04 PM") + " (" + meal.Open.Local().Format("Mon Jan 02, 2006") + ")",
		Inline: true,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Menu",
		Value:  strconv.Itoa(len(meal.MenuItems)) + " menu items",
		Inline: true,
	})
	embeds = append(embeds, &discordgo.MessageEmbed{
		Title:  "New " + meal.Name + " Meal Fetched!",
		Color:  10181046,
		Fields: fields,
	})
	_, err := Discord.ChannelMessageSendEmbeds(config.DiscordChannel, embeds)
	if err != nil {
		println(err.Error())
	}
}
