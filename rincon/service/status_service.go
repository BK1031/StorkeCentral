package service

import (
	"github.com/bwmarrin/discordgo"
	"github.com/gin-gonic/gin"
	gomail "gopkg.in/gomail.v2"
	"net/http"
	"rincon/config"
	"rincon/model"
	"rincon/utils"
	"strconv"
	"strings"
	"time"
)

func GetServiceStatus(service model.Service) gin.H {
	utils.SugarLogger.Infoln("Pinging " + service.URL)
	start := time.Now()
	res, err := http.Get(service.URL + "/" + strings.ToLower(service.Name) + "/ping")
	elapsed := time.Since(start).Milliseconds()
	if err != nil {
		SendStatusEmail(service, false)
		SendStatusLog(service, false)
		// Remove service from registry
		if err := RemoveService(service); err != nil {
			utils.SugarLogger.Errorln("Failed to remove service from registry")
		}
		return gin.H{"status": false, "message": "Failed to make contact with specified service", "service": service, "ping": elapsed}
	}
	defer res.Body.Close()
	utils.SugarLogger.Infoln(res.Status)
	SendStatusEmail(service, true)
	SendStatusLog(service, true)
	return gin.H{"status": true, "message": service.Name + " v" + service.Version + " is online!", "service": service, "ping": elapsed}
}

func SendStatusEmail(service model.Service, status bool) {
	m := gomail.NewMessage()
	m.SetHeader("From", "bk1031dev@gmail.com")
	m.SetAddressHeader("To", service.StatusEmail, "Statuspage")
	if status {
		m.SetHeader("Subject", "UP - "+time.Now().String())
	} else {
		m.SetHeader("Subject", "DOWN - "+time.Now().String())
	}
	if err := gomail.Send(sender, m); err != nil {
		utils.SugarLogger.Errorln("Could not send email to %q: %v", service.StatusEmail, err)
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Statuspage update email sent")
	m.Reset()
}

func SendStatusLog(service model.Service, status bool) {
	var embed = discordgo.MessageEmbed{}
	embed.URL = "https://storkecentral.statuspage.io/"
	if status {
		embed.Color = 4915066
		embed.Description = "Successfully reached service!"
	} else {
		embed.Color = 16730698
		embed.Description = "Failed to reach service!"
	}
	embed.Fields = append(embed.Fields, &discordgo.MessageEmbedField{
		Name:   "ID",
		Value:  strconv.Itoa(service.ID),
		Inline: true,
	})
	embed.Fields = append(embed.Fields, &discordgo.MessageEmbedField{
		Name:   "Version",
		Value:  service.Version,
		Inline: true,
	})
	embed.Fields = append(embed.Fields, &discordgo.MessageEmbedField{
		Name:   "Port",
		Value:  strconv.Itoa(int(service.Port)),
		Inline: true,
	})
	embed.Title = service.Name
	embed.Footer = &discordgo.MessageEmbedFooter{
		Text:         "Rincon v" + config.Version,
		IconURL:      "",
		ProxyIconURL: "",
	}
	_, _ = Discord.ChannelMessageSendEmbed(config.DiscordChannel, &embed)
	if !status {
		_, _ = Discord.ChannelMessageSend(config.DiscordChannel, ":fire: :fire: :fire: <@&981503871396511775> service down fuck fuck fuck :fire: :fire: :fire:\nhttps://storkecentral.statuspage.io/")
	}
}
