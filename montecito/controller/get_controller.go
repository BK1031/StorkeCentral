package controller

import (
	"encoding/json"
	"github.com/gin-gonic/gin"
	"io"
	"montecito/config"
	"montecito/model"
	"montecito/service"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func GetProxy(c *gin.Context) {
	startTime := time.Now()
	requestID := c.GetHeader("Request-ID")
	// Get service to handle route
	mappedService := service.MatchRoute(strings.Split(c.Request.URL.String(), "/")[1], requestID)
	if mappedService.ID != 0 {
		println("PROXY TO: (" + strconv.Itoa(mappedService.ID) + ") " + mappedService.Name + " @ " + mappedService.URL)
		proxyClient := &http.Client{}
		proxyRequest, _ := http.NewRequest("GET", "http://localhost"+":"+strconv.Itoa(mappedService.Port)+c.Request.URL.String(), nil) // Use this when not running in Docker
		//proxyRequest, _ := http.NewRequest("GET", mappedService.URL+c.Request.URL.String(), nil)
		// Transfer headers to proxy request
		proxyRequest.Header.Set("Request-ID", requestID)
		for header, values := range c.Request.Header {
			for _, value := range values {
				proxyRequest.Header.Add(header, value)
			}
		}
		// Proxy the actual request
		proxyResponse, err := proxyClient.Do(proxyRequest)
		if err != nil {
			println("Failed to proxy request to " + mappedService.Name + ": " + err.Error())
			c.JSON(http.StatusServiceUnavailable, model.Response{
				Status:    "ERROR",
				Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   mappedService.Name + " v" + mappedService.Version,
				Timestamp: time.Now().Format(time.RubyDate),
				Data:      json.RawMessage("{\"message\": \"Failed to reach " + mappedService.Name + "! Is the service online?\"}"),
			})
		} else {
			println("Successfully proxied request to " + mappedService.Name + "!")
			defer proxyResponse.Body.Close()
			// Transfer body from proxy response
			responseModel := model.Response{
				Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   mappedService.Name + " v" + mappedService.Version,
				Timestamp: time.Now().Format(time.RubyDate),
			}
			var proxyResponseBodyBytes []byte
			proxyResponseBodyBytes, err = io.ReadAll(proxyResponse.Body)
			//println("PROXY RESPONSE: " + string(proxyResponseBodyBytes))
			if err != nil {
				// Failed to decode response body
				println(err.Error())
				c.JSON(http.StatusInternalServerError, model.Response{
					Status:    "ERROR",
					Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
					Gateway:   "Montecito v" + config.Version,
					Service:   mappedService.Name + " v" + mappedService.Version,
					Timestamp: time.Now().Format(time.RubyDate),
					Data:      json.RawMessage("{\"message\": \"Failed to decode service response body: " + err.Error() + "\"}"),
				})
			} else {
				responseModel.Data = json.RawMessage(string(proxyResponseBodyBytes))
				// Transfer status from proxy response
				if proxyResponse.StatusCode >= 200 && proxyResponse.StatusCode < 300 {
					responseModel.Status = "SUCCESS"
				} else {
					responseModel.Status = "ERROR"
				}
				// Transfer headers from proxy response
				for header, values := range proxyResponse.Header {
					if header != "Content-Length" && header != "Connection" && header != "Date" {
						for _, value := range values {
							c.Header(header, value)
						}
					}
				}
				c.Header("Request-ID", requestID)
				c.JSON(proxyResponse.StatusCode, responseModel)
			}
		}
	} else {
		c.JSON(http.StatusBadGateway, model.Response{
			Status:    "ERROR",
			Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
			Gateway:   "Montecito v" + config.Version,
			Service:   config.RinconService.Name + " v" + config.RinconService.Version,
			Timestamp: time.Now().Format(time.RubyDate),
			Data:      json.RawMessage("{\"message\": \"No service to handle route: " + c.Request.URL.String() + "\"}"),
		})
	}
	// TODO: Discord logging
	return
}

func PostProxy(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Montecito v" + config.Version + " is online!"})
}

func DeleteProxy(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Montecito v" + config.Version + " is online!"})
}
