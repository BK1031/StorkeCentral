package service

import (
	"fmt"
	"github.com/bwmarrin/discordgo"
	"tepusquet/config"
	"tepusquet/model"
)

var Discord *discordgo.Session

func ConnectDiscord() {
	dg, err := discordgo.New("Bot " + config.DiscordToken)
	if err != nil {
		fmt.Println("Error creating Discord session, ", err)
		return
	}
	Discord = dg
	_, err = Discord.ChannelMessageSend(config.DiscordChannel, ":white_check_mark: Tepusquet v"+config.Version+" online! `[ENV = "+config.Env+"]`")
	if err != nil {
		fmt.Println("Error sending Discord message, ", err)
		return
	}
}

func DiscordLogNewCourse(course model.UserCourse) {
	var embeds []*discordgo.MessageEmbed
	var fields []*discordgo.MessageEmbedField
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "UserID",
		Value:  course.UserID,
		Inline: false,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "CourseID",
		Value:  course.CourseID,
		Inline: true,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Quarter",
		Value:  course.Quarter,
		Inline: true,
	})
	embeds = append(embeds, &discordgo.MessageEmbed{
		Title:  "New Course Fetched!",
		Color:  15844367,
		Fields: fields,
	})
	_, err := Discord.ChannelMessageSendEmbeds(config.DiscordChannel, embeds)
	if err != nil {
		println(err.Error())
	}
}
