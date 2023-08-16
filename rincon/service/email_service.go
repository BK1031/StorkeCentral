package service

import (
	gomail "gopkg.in/gomail.v2"
	"rincon/config"
	"rincon/utils"
)

var sender gomail.SendCloser

func SetupGomailClient() {
	d := gomail.NewDialer("smtp.gmail.com", 587, config.EmailAddress, config.EmailPassword)
	s, err := d.Dial()
	if err != nil {
		utils.SugarLogger.Errorln("Error connecting to Gmail SMTP, ", err)
	}
	sender = s
}
