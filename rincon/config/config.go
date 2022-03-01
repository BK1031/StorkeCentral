package config

import "os"

var Version = "1.1.0"
var Port = os.Getenv("PORT")

var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")

var EmailAddress = os.Getenv("EMAIL_ADDRESS")
var EmailPassword = os.Getenv("EMAIL_PASSWORD")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var StatusEmail = os.Getenv("STATUS_EMAIL")