package config

import (
	"montecito/model"
	"os"
)

var Service = model.Service{}

var Version = "2.0.2"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")
var RinconPort = os.Getenv("RINCON_PORT")
var RinconService = model.Service{}
var JaegerPort = os.Getenv("JAEGER_PORT")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var StatusEmail = os.Getenv("STATUS_EMAIL")

var FirebaseServiceAccountEncoded = os.Getenv("FIREBASE_SERVICE_ACCOUNT")

var APIKeys []model.APIKey
