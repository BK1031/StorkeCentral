package config

import "os"

var Version = "1.5.0"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")
var RinconPort = os.Getenv("RINCON_PORT")
var CurrentQuarter = os.Getenv("CURRENT_QUARTER")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var CredEncryptionKey = os.Getenv("CRED_ENCRYPTION_KEY")
var UpNextUpdateDelay = os.Getenv("UPNEXT_UPDATE_DELAY")
var NotificationUpdateDelay = os.Getenv("NOTIFICATION_UPDATE_DELAY")

var StatusEmail = os.Getenv("STATUS_EMAIL")

var FirebaseServiceAccountEncoded = os.Getenv("FIREBASE_SERVICE_ACCOUNT")
