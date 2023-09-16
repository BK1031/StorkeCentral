package config

import (
	"os"
	"rincon/model"
	"strings"
)

var Service = model.Service{
	Name:        os.Getenv("SERVICE_NAME"),
	StatusEmail: os.Getenv("STATUS_EMAIL"),
	URL:         "http://" + strings.ToLower(os.Getenv("SERVICE_NAME")) + ":" + Port,
	Version:     Version,
}

var Version = "1.5.1"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")
var JaegerPort = os.Getenv("JAEGER_PORT")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var EmailAddress = os.Getenv("EMAIL_ADDRESS")
var EmailPassword = os.Getenv("EMAIL_PASSWORD")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")
var StatusChannel = os.Getenv("STATUS_CHANNEL")

var RegistryUpdateCron = os.Getenv("REGISTRY_UPDATE_CRON")
