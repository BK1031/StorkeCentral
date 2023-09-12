package controller

import (
	"bytes"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/attribute"
	oteltrace "go.opentelemetry.io/otel/trace"
	"io"
	"montecito/config"
	"montecito/model"
	"montecito/service"
	"montecito/utils"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func PostProxy(c *gin.Context) {
	startTime, _ := c.Get("startTime")
	requestID := c.GetHeader("Request-ID")
	c.Header("Request-ID", requestID)
	// Start tracing span
	span := utils.BuildSpan(c.Request.Context(), "[POST] "+c.Request.URL.String(), oteltrace.WithAttributes(attribute.Key("Request-ID").String(requestID)))
	defer span.End()
	// Get service to handle route
	mappedService := service.MatchRoute(utils.BuildTraceparent(span), strings.TrimLeft(c.Request.URL.String(), "/"), requestID)
	if mappedService.ID != 0 {
		if service.VerifyAPIKeyScopes(c.Request.Header.Get("SC-API-KEY"), mappedService, c.Request.Method) {
			utils.SugarLogger.Infoln("PROXY TO: (" + strconv.Itoa(mappedService.ID) + ") " + mappedService.Name + " @ " + mappedService.URL)
			proxyClient := &http.Client{}
			//proxyRequest, _ := http.NewRequest("POST", "http://localhost"+":"+strconv.Itoa(mappedService.Port)+c.Request.URL.String(), nil) // Use this when not running in Docker
			proxyRequest, _ := http.NewRequest("POST", mappedService.URL+c.Request.URL.String(), nil)
			// Transfer headers to proxy request
			proxyRequest.Header.Set("Request-ID", requestID)
			proxyRequest.Header.Set("traceparent", utils.BuildTraceparent(span))
			for header, values := range c.Request.Header {
				for _, value := range values {
					proxyRequest.Header.Add(header, value)
				}
			}
			// Transfer body to proxy request
			var requestBodyBytes []byte
			requestBodyBytes, err := io.ReadAll(c.Request.Body)
			if err != nil {
				utils.SugarLogger.Errorln("Failed to read request body: " + err.Error())
			}
			proxyRequest.Body = io.NopCloser(bytes.NewBuffer(requestBodyBytes))
			proxyRequest = proxyRequest.WithContext(oteltrace.ContextWithSpan(c.Request.Context(), span))
			// Proxy the actual request
			proxyResponse, err := proxyClient.Do(proxyRequest)
			if err != nil {
				utils.SugarLogger.Errorln("Failed to proxy request to " + mappedService.Name + ": " + err.Error())
				c.JSON(http.StatusServiceUnavailable, model.Response{
					Status:    "ERROR",
					Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
					Gateway:   "Montecito v" + config.Version,
					Service:   mappedService.Name + " v" + mappedService.Version,
					Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
					Data:      json.RawMessage("{\"message\": \"Failed to reach " + mappedService.Name + "! Is the service online?\"}"),
				})
			} else {
				utils.SugarLogger.Infoln("Successfully proxied request to " + mappedService.Name + "!")
				defer proxyResponse.Body.Close()
				// Transfer body from proxy response
				responseModel := model.Response{
					Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
					Gateway:   "Montecito v" + config.Version,
					Service:   mappedService.Name + " v" + mappedService.Version,
					Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
				}
				var proxyResponseBodyBytes []byte
				proxyResponseBodyBytes, err = io.ReadAll(proxyResponse.Body)
				if err != nil {
					//	Failed to decode response body
					utils.SugarLogger.Errorln(err.Error())
					c.JSON(http.StatusInternalServerError, model.Response{
						Status:    "ERROR",
						Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
						Gateway:   "Montecito v" + config.Version,
						Service:   mappedService.Name + " v" + mappedService.Version,
						Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
						Data:      json.RawMessage("{\"message\": \"Failed to decode service response body: " + err.Error() + "\"}"),
					})
				} else {
					err = json.Unmarshal(proxyResponseBodyBytes, &responseModel.Data)
					if err != nil {
						// JSON marshalling failed, return body as string
						utils.SugarLogger.Errorln("Failed to unmarshall response body, returning as message string: " + err.Error())
						responseModel.Data = json.RawMessage("{\"message\": \"" + string(proxyResponseBodyBytes) + "\"}")
					}
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
					c.JSON(proxyResponse.StatusCode, responseModel)
				}
			}
		} else {
			c.JSON(http.StatusUnauthorized, model.Response{
				Status:    "ERROR",
				Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   mappedService.Name + " v" + mappedService.Version,
				Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
				Data:      json.RawMessage("{\"message\": \"Given API key has insufficient scope to access this service!\"}"),
			})
		}
	} else {
		c.JSON(http.StatusBadGateway, model.Response{
			Status:    "ERROR",
			Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
			Gateway:   "Montecito v" + config.Version,
			Service:   config.RinconService.Name + " v" + config.RinconService.Version,
			Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
			Data:      json.RawMessage("{\"message\": \"No service to handle route: " + c.Request.URL.String() + "\"}"),
		})
	}
	go service.DiscordLogRequest(c)
	return
}
