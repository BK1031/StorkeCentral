package config

import "os"

var Version = "1.0.1"
var Env = os.Getenv("ENV")
var Port = os.Getenv("PORT")
var RinconPort = os.Getenv("RINCON_PORT")

var PostgresHost = os.Getenv("POSTGRES_HOST")
var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")
var PostgresPort = os.Getenv("POSTGRES_PORT")

var DiscordToken = os.Getenv("DISCORD_TOKEN")
var DiscordGuild = os.Getenv("DISCORD_GUILD")
var DiscordChannel = os.Getenv("DISCORD_CHANNEL")

var StatusEmail = os.Getenv("STATUS_EMAIL")

var FirebaseServiceAccountEncoded = os.Getenv("FIREBASE_SERVICE_ACCOUNT")

var CredEncryptionKey = os.Getenv("CRED_ENCRYPTION_KEY")
var CredEncryptionNonce = os.Getenv("CRED_ENCRYPTION_NONCE")
