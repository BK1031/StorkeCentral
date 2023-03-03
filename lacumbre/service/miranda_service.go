package service

import (
	"bytes"
	"net/http"
)

func SendMirandaNotification(mirandaBody []byte) {
	// TODO: Make this actually get the correct miranda dns value
	responseBody := bytes.NewBuffer(mirandaBody)
	_, err := http.Post("miranda"+":"+"4007"+"/notifications", "application/json", responseBody)
	if err != nil {
		println("Error sending notification :(")
	} else {
		println("Sent notification to Miranda!")
	}
}
