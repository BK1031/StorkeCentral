package service

import (
	"github.com/gin-gonic/gin"
	"gopkg.in/gomail.v2"
	"log"
	"net/http"
	"rincon/model"
	"strings"
	"time"
)

func GetServiceStatus(service model.Service) gin.H {
	println("Pinging " + service.URL)
	res, err := http.Get(service.URL + "/" + strings.ToLower(service.Name) + "/ping")
	if err != nil {
		SendStatusEmail(service, false)
		// Remove service from registry
		if err := RemoveService(service); err != nil {
			println("Failed to remove service from registry")
		}
		return gin.H{"status": "404", "message": "Failed to make contact with specified service", "service": service}
	}
	println(res.Status)
	SendStatusEmail(service, true)
	return gin.H{"status": res.StatusCode, "message": service.Name + " v" + service.Version + " is online!", "service": service}
}

func SendStatusEmail(service model.Service, status bool) {
	m := gomail.NewMessage()
	m.SetHeader("From", "bk1031dev@gmail.com")
	m.SetAddressHeader("To", service.StatusEmail, "Statuspage")
	if status {
		m.SetHeader("Subject", "UP - " + time.Now().String())
	} else {
		m.SetHeader("Subject", "DOWN - " + time.Now().String())
	}
	if err := gomail.Send(sender, m); err != nil {
		log.Printf("Could not send email to %q: %v", service.StatusEmail, err)
	}
	m.Reset()
}
