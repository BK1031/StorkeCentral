package service

import (
	"fmt"
	"gopkg.in/gomail.v2"
	"rincon/config"
)

var sender gomail.SendCloser

func SetupGomailClient() {
	d := gomail.NewDialer("smtp.gmail.com", 587, config.EmailAddress, config.EmailPassword)
	s, err := d.Dial()
	if err != nil {
		fmt.Println("Error connecting to Gmail SMTP, ", err)
	}
	sender = s;
}
