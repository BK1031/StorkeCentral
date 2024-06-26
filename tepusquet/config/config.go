package config

import (
	"os"
	"strings"
	"tepusquet/model"
)

var Service = model.Service{
	Name:        os.Getenv("SERVICE_NAME"),
	StatusEmail: os.Getenv("STATUS_EMAIL"),
	URL:         "http://" + strings.ToLower(os.Getenv("SERVICE_NAME")) + ":" + Port,
	Version:     Version,
}

var Version = "2.3.7"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")
var RinconPort = os.Getenv("RINCON_PORT")
var JaegerPort = os.Getenv("JAEGER_PORT")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var CredEncryptionKey = os.Getenv("CRED_ENCRYPTION_KEY")

var FirebaseProjectID = os.Getenv("FIREBASE_PROJECT_ID")
var FirebaseServiceAccountEncoded = os.Getenv("FIREBASE_SERVICE_ACCOUNT")

var CurrentQuarter = os.Getenv("CURRENT_QUARTER")
var CurrentPasstimeQuarter = os.Getenv("CURRENT_PASSTIME_QUARTER")
var UpNextUpdateCron = os.Getenv("UP_NEXT_UPDATE_CRON")
var NotificationCron = os.Getenv("NOTIFICATION_CRON")
