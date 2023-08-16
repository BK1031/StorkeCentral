package service

import (
	"bytes"
	"encoding/json"
	"net/http"
	"strconv"
	"tepusquet/config"
	"tepusquet/utils"
	"time"
)

var rinconRetries = 0
var rinconHost = "http://rincon"

func RegisterRincon() {
	var portInt, _ = strconv.Atoi(config.Port)
	rinconBody, _ := json.Marshal(map[string]interface{}{
		"name":         "Tepusquet",
		"version":      config.Version,
		"url":          "http://tepusquet:" + config.Port,
		"port":         portInt,
		"status_email": config.StatusEmail,
	})
	responseBody := bytes.NewBuffer(rinconBody)
	res, err := http.Post(rinconHost+":"+config.RinconPort+"/services", "application/json", responseBody)
	if err != nil {
		if rinconRetries < 15 {
			rinconRetries++
			if rinconRetries%2 == 0 {
				rinconHost = "http://localhost"
				utils.SugarLogger.Errorln("failed to register with rincon, retrying with \"http://localhost\" in 5s...")
			} else {
				rinconHost = "http://rincon"
				utils.SugarLogger.Errorln("failed to register with rincon, retrying with \"http://rincon\" in 5s...")
			}
			time.Sleep(time.Second * 5)
			RegisterRincon()
		} else {
			utils.SugarLogger.Fatalln("failed to register with rincon after 15 attempts, terminating program...")
		}
	} else {
		defer res.Body.Close()
		if res.StatusCode == 200 {
			json.NewDecoder(res.Body).Decode(&config.Service)
		}
		utils.SugarLogger.Infoln("Registered service with Rincon! Service ID: " + strconv.Itoa(config.Service.ID))
		RegisterRinconRoute("/tepusquet")
		RegisterRinconRoute("/users/credentials")
		RegisterRinconRoute("/users/courses")
		RegisterRinconRoute("/users/schedule")
		RegisterRinconRoute("/users/passtime")
	}
}

func RegisterRinconRoute(route string) {
	rinconBody, _ := json.Marshal(map[string]string{
		"route":        route,
		"service_name": "Tepusquet",
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post(rinconHost+":"+config.RinconPort+"/routes", "application/json", responseBody)
	if err != nil {
	}
	utils.SugarLogger.Infoln("Registered route " + route)
}
