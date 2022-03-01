package service

import (
	"github.com/bwmarrin/discordgo"
	"github.com/gin-gonic/gin"
	"gopkg.in/gomail.v2"
	"log"
	"net/http"
	"rincon/config"
	"rincon/model"
	"strconv"
	"strings"
	"time"
)

func GetServiceStatus(service model.Service) gin.H {
	println("Pinging " + service.URL)
	start := time.Now()
	res, err := http.Get(service.URL + "/" + strings.ToLower(service.Name) + "/ping")
	elapsed := time.Since(start).Milliseconds()
	if err != nil {
		SendStatusEmail(service, false)
		SendStatusLog(service, false)
		// Remove service from registry
		if err := RemoveService(service); err != nil {
			println("Failed to remove service from registry")
		}
		return gin.H{"status": "404", "message": "Failed to make contact with specified service", "service": service, "ping": elapsed}
	}
	defer res.Body.Close()
	println(res.Status)
	SendStatusEmail(service, true)
	SendStatusLog(service, true)
	return gin.H{"status": res.StatusCode, "message": service.Name + " v" + service.Version + " is online!", "service": service, "ping": elapsed}
}

func SendStatusEmail(service model.Service, status bool) {
	m := gomail.NewMessage()
	m.SetHeader("From", "bk1031dev@gmail.com")
	m.SetAddressHeader("To", service.StatusEmail, "Statuspage")
	if status {
		m.SetHeader("Subject", "UP - " + time.Now().String())
	} else {
		m.SetHeader("Subject", "DOWN - " + time.Now().String())
	}
	if err := gomail.Send(sender, m); err != nil {
		log.Printf("Could not send email to %q: %v", service.StatusEmail, err)
	}
	_, _ = discord.ChannelMessageSend(config.DiscordChannel, "Statuspage update email sent")
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
		Value: strconv.Itoa(service.ID),
		Inline: true,
	})
	embed.Fields = append(embed.Fields, &discordgo.MessageEmbedField{
		Name:   "Version",
		Value:  service.Version,
		Inline: true,
	})
	embed.Fields = append(embed.Fields, &discordgo.MessageEmbedField{
		Name:   "Port",
		Value: strconv.Itoa(int(service.Port)),
		Inline: true,
	})
	embed.Title = service.Name
	embed.Footer = &discordgo.MessageEmbedFooter{
		Text:         "Rincon v" + config.Version,
		IconURL:      "",
		ProxyIconURL: "",
	}
	_, _ = discord.ChannelMessageSendEmbed(config.DiscordChannel, &embed)
}
