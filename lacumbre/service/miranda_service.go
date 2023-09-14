package service

import (
	"github.com/go-resty/resty/v2"
	"lacumbre/utils"
)

type MirandaNotification struct {
	ID         string        `json:"id"`
	UserID     string        `json:"user_id"`
	Sender     string        `json:"sender"`
	Title      string        `json:"title"`
	Body       string        `json:"body"`
	PictureUrl string        `json:"picture_url"`
	LaunchUrl  string        `json:"launch_url"`
	Route      string        `json:"route"`
	Priority   string        `json:"priority"`
	Push       bool          `json:"push"`
	Read       bool          `json:"read"`
	Data       []interface{} `json:"data"`
}

func SendMirandaNotification(mirandaBody MirandaNotification, requestID string, traceparent string) {
	mappedService := MatchRoute("miranda", "", "")
	if mappedService.ID != 0 {
		client := resty.New()
		resp, err := client.R().
			SetBody(mirandaBody).
			SetHeader("Request-ID", requestID).
			SetHeader("traceparent", traceparent).
			Post(mappedService.URL + "/notifications")
		if err != nil {
			utils.SugarLogger.Errorln("Failed to send miranda notification: " + err.Error())
		} else {
			utils.SugarLogger.Infoln("Sent miranda notification with response: " + resp.Status())
		}
	} else {
		utils.SugarLogger.Errorln("Failed to send miranda notification, no miranda service found!")
	}
}
