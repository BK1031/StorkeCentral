package service

import (
	"bytes"
	"encoding/json"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/utils"
	"net/http"
	"strconv"
	"time"
)

var rinconRetries = 0
var rinconHost = "http://rincon"

func RegisterRincon() {
	var portInt, _ = strconv.Atoi(config.Port)
	rinconBody, _ := json.Marshal(map[string]interface{}{
		"name":         "Lacumbre",
		"version":      config.Version,
		"url":          "http://lacumbre:" + config.Port,
		"port":         portInt,
		"status_email": config.StatusEmail,
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post(rinconHost+":"+config.RinconPort+"/services", "application/json", responseBody)
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
		GetServiceInfo()
		utils.SugarLogger.Infoln("Registered service with Rincon! Service ID: " + strconv.Itoa(config.Service.ID))
		RegisterRinconRoute("/lacumbre")
		RegisterRinconRoute("/users")
	}
}

func RegisterRinconRoute(route string) {
	rinconBody, _ := json.Marshal(map[string]string{
		"route":        route,
		"service_name": "Lacumbre",
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post(rinconHost+":"+config.RinconPort+"/routes", "application/json", responseBody)
	if err != nil {
	}
	utils.SugarLogger.Infoln("Registered route " + route)
}

func GetServiceInfo() {
	var service model.Service
	rinconClient := http.Client{}
	req, _ := http.NewRequest("GET", rinconHost+":"+config.RinconPort+"/routes/match/lacumbre", nil)
	res, err := rinconClient.Do(req)
	if err != nil {
		utils.SugarLogger.Errorln(err.Error())
	}
	defer res.Body.Close()
	if res.StatusCode == 200 {
		json.NewDecoder(res.Body).Decode(&service)
	}
	config.Service = service
}
