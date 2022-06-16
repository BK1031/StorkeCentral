package config

import "os"

var Version = "1.3.6"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var EmailAddress = os.Getenv("EMAIL_ADDRESS")
var EmailPassword = os.Getenv("EMAIL_PASSWORD")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var StatusEmail = os.Getenv("STATUS_EMAIL")

var RegistryUpdateDelay = os.Getenv("REGISTRY_UPDATE_DELAY")