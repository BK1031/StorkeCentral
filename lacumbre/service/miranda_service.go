package service

import (
	"bytes"
	"lacumbre/utils"
	"net/http"
)

func SendMirandaNotification(mirandaBody []byte) {
	// TODO: Make this actually get the correct miranda dns value
	responseBody := bytes.NewBuffer(mirandaBody)
	_, err := http.Post("http://miranda"+":"+"4007"+"/notifications", "application/json", responseBody)
	if err != nil {
		utils.SugarLogger.Errorln("Error sending notification :(" + err.Error())
	} else {
		utils.SugarLogger.Infoln("Sent notification to Miranda!")
	}
}
