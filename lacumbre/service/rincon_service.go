package service

import (
	"bytes"
	"encoding/json"
	"lacumbre/config"
	"lacumbre/model"
	"lacumbre/utils"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var rinconRetries = 0
var rinconHost = "http://localhost:" + config.RinconPort

func RegisterRincon() {
	var portInt, _ = strconv.Atoi(config.Port)
	config.Service.Port = portInt

	// Azure Container App deployment
	ContainerAppEnvDNSSuffix := os.Getenv("CONTAINER_APP_ENV_DNS_SUFFIX")
	if ContainerAppEnvDNSSuffix != "" {
		utils.SugarLogger.Infoln("Detected Azure Container App deployment, using environment dns suffix: " + ContainerAppEnvDNSSuffix)
		config.Service.URL = "http://" + strings.ToLower(config.Service.Name) + ".internal." + ContainerAppEnvDNSSuffix
		rinconHost = "http://rincon.internal." + ContainerAppEnvDNSSuffix
	}

	utils.SugarLogger.Infoln("Attempting to register service with Rincon @ " + rinconHost + "/services")
	rinconBody, _ := json.Marshal(config.Service)
	reqBody := bytes.NewBuffer(rinconBody)
	res, err := http.Post(rinconHost+"/services", "application/json", reqBody)
	if err != nil {
		if rinconRetries < 10 {
			rinconRetries++
			if rinconRetries%2 == 0 {
				rinconHost = "http://rincon:" + config.RinconPort
			} else {
				rinconHost = "http://localhost:" + config.RinconPort
			}
			utils.SugarLogger.Errorln("failed, retrying with in 5s...")
			time.Sleep(time.Second * 5)
			RegisterRincon()
		} else {
			utils.SugarLogger.Fatalln("failed to register with rincon after 10 attempts, terminating program...")
		}
	} else {
		defer res.Body.Close()
		if res.StatusCode == 200 {
			json.NewDecoder(res.Body).Decode(&config.Service)
		}
		utils.SugarLogger.Infoln("Registered service with Rincon! Service ID: " + strconv.Itoa(config.Service.ID))
		RegisterRinconRoute("/" + strings.ToLower(config.Service.Name))
		RegisterRinconRoute("/users")
	}
}

func RegisterRinconRoute(route string) {
	rinconBody, _ := json.Marshal(map[string]string{
		"route":        route,
		"service_name": config.Service.Name,
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post(rinconHost+"/routes", "application/json", responseBody)
	if err != nil {
	}
	utils.SugarLogger.Infoln("Registered route " + route)
}

func MatchRoute(route string, requestID string) model.Service {
	var service model.Service
	queryRoute := strings.ReplaceAll(route, "/", "<->")
	rinconClient := http.Client{}
	req, _ := http.NewRequest("GET", rinconHost+"/routes/match/"+queryRoute, nil)
	req.Header.Set("Request-ID", requestID)
	req.Header.Add("Content-Type", "application/json")
	res, err := rinconClient.Do(req)
	if err != nil {
		utils.SugarLogger.Errorln(err.Error())
		return service
	}
	defer res.Body.Close()
	if res.StatusCode == 200 {
		json.NewDecoder(res.Body).Decode(&service)
	}
	return service
}
