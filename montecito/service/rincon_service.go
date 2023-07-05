package service

import (
	"bytes"
	"encoding/json"
	"montecito/config"
	"montecito/model"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var rinconRetries = 0
var rinconHost = "http://rincon"

func RegisterRincon() {
	var portInt, _ = strconv.Atoi(config.Port)
	rinconBody, _ := json.Marshal(map[string]interface{}{
		"name":         "Montecito",
		"version":      config.Version,
		"url":          "http://montecito:" + config.Port,
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
				println("failed to register with rincon, retrying with \"http://localhost\" in 5s...")
			} else {
				rinconHost = "http://rincon"
				println("failed to register with rincon, retrying with \"http://rincon\" in 5s...")
			}
			time.Sleep(time.Second * 5)
			RegisterRincon()
		} else {
			println("failed to register with rincon after 15 attempts, terminating program...")
			os.Exit(100)
		}
	} else {
		println("Registered service with Rincon!")
		RegisterRinconRoute("/montecito")
	}
}

func RegisterRinconRoute(route string) {
	rinconBody, _ := json.Marshal(map[string]string{
		"route":        route,
		"service_name": "Montecito",
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post(rinconHost+":"+config.RinconPort+"/routes", "application/json", responseBody)
	if err != nil {
	}
	println("Registered route " + route)
}

func MatchRoute(route string, requestID string) model.Service {
	queryRoute := strings.ReplaceAll(route, "/", "-")
	//http.Get(rinconHost + ":" + config.RinconPort + "/routes/match/" + queryRoute)
	rinconClient := &http.Client{}
	req, _ := http.NewRequest("GET", rinconHost+":"+config.RinconPort+"/routes/match/"+queryRoute, nil)
	req.Header.Set("Request-ID", requestID)
	req.Header.Add("Content-Type", "application/json")
	res, err := rinconClient.Do(req)
	if err != nil {
		println(err.Error())
	}
	defer res.Body.Close()
	if res.StatusCode == 200 {
		var service model.Service
		json.NewDecoder(res.Body).Decode(&service)
		return service
	}
	return model.Service{}
}
