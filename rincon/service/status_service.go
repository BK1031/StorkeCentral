package service

import (
	"github.com/gin-gonic/gin"
	"io/ioutil"
	"net/http"
	"rincon/model"
	"strings"
)

func GetServiceStatus(service model.Service) gin.H {
	println("Pinging " + service.URL)
	res, err := http.Get(service.URL + "/" + strings.ToLower(service.Name) + "/ping")
	if err != nil {
		println(err)
		return gin.H{"status": "404", "message": "Failed to make contact with specified service", "service": service}
	}
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		println(err)
	}
	sb := string(body)
	println(res.Status)
	return gin.H{"status": res.StatusCode, "message": sb, "service": service}
}
