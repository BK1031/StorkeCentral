package config

import "os"

var Version = "1.0.0"
var Port = os.Getenv("PORT")

var PostgresUser = os.Getenv("POSTGRES_USER")
var PostgresPassword = os.Getenv("POSTGRES_PASSWORD")

var EmailAddress = os.Getenv("EMAIL_ADDRESS")
var EmailPassword = os.Getenv("EMAIL_PASSWORD")