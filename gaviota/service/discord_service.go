package service

import (
	"gaviota/config"
	"gaviota/model"
	"gaviota/utils"
	"github.com/bwmarrin/discordgo"
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

func DiscordLogNewArticle(article model.Article) {
	var embeds []*discordgo.MessageEmbed
	var fields []*discordgo.MessageEmbedField
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "ID",
		Value:  article.ID,
		Inline: false,
	})
	fields = append(fields, &discordgo.MessageEmbedField{
		Name:   "Title",
		Value:  article.Title,
		Inline: true,
	})
	embeds = append(embeds, &discordgo.MessageEmbed{
		Title: "New Article Created!",
		Color: 6609663,
		Author: &discordgo.MessageEmbedAuthor{
			URL:  article.ArticleURL,
			Name: article.ByLine,
		},
		Fields:      fields,
		Description: article.Excerpt,
	})
	_, err := Discord.ChannelMessageSendEmbeds(config.DiscordChannel, embeds)
	if err != nil {
		utils.SugarLogger.Errorln(err.Error())
	}
}
