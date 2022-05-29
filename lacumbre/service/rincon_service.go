package service

import (
	"bytes"
	"encoding/json"
	"lacumbre/config"
	"net/http"
	"os"
	"strconv"
	"time"
)

var rinconRetries = 0

func RegisterRincon() {
	var portInt, _ = strconv.Atoi(config.Port)
	rinconBody, _ := json.Marshal(map[string]interface{}{
		"name": "Lacumbre",
		"version": config.Version,
		"url": "http://lacumbre:" + config.Port,
		"port": portInt,
		"status_email": config.StatusEmail,
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post("http://rincon:" + config.RinconPort + "/services", "application/json", responseBody)
	if err != nil {
		if rinconRetries < 15 {
			rinconRetries++
			println("failed to register with rincon, retrying in 5s...")
			time.Sleep(time.Second * 5)
			RegisterRincon()
		} else {
			println("failed to register with rincon after 15 attempts, terminating program...")
			os.Exit(100)
		}
	} else {
		println("Registered service with Rincon!")
		RegisterRinconRoute("/lacumbre")
		RegisterRinconRoute("/users")
	}
}

func RegisterRinconRoute(route string) {
	rinconBody, _ := json.Marshal(map[string]string{
		"route": route,
		"service_name": "Lacumbre",
	})
	responseBody := bytes.NewBuffer(rinconBody)
	_, err := http.Post("http://rincon:" + config.RinconPort + "/routes", "application/json", responseBody)
	if err != nil {}
	println("Registered route " + route)
}