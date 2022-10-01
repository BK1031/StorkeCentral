package service

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"lacumbre/config"
	"lacumbre/model"
)

var Discord *discordgo.Session;

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		fmt.Println("Error creating Discord session, ", err)
		return
	}
	Discord = dg
	_, err = Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Lacumbre v" + config.Version + " online! `[ENV = " + config.Env + "]`")
	if err != nil {
		fmt.Println("Error sending Discord message, ", err)
		return
	}
}

func DiscordLogNewUser(user model.User) {
	var embeds []*discordgo.MessageEmbed
	var fields []*discordgo.MessageEmbedField
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "ID",
		Value:  user.ID,
		Inline: false,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Email",
		Value:  user.Email,
		Inline: true,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Phone",
		Value:  user.PhoneNumber,
		Inline: true,
	})
	embeds = append(embeds, &discordgo.MessageEmbed{
		Title:       "New Account Created!",
		Color:       6609663,
		Author:      &discordgo.MessageEmbedAuthor{
			URL:          "https://storkecentr.al/u/" + user.UserName,
			Name:         user.FirstName + " " + user.LastName,
			IconURL:      user.ProfilePictureURL,
		},
		Fields: fields,
	})
	_, err := Discord.ChannelMessageSendEmbeds(config.DiscordChannel, embeds)
	if err != nil {
		println(err.Error())
	}
}