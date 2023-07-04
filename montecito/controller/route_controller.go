package controller

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"io"
	"log"
	"montecito/config"
	"montecito/model"
	"montecito/service"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func InitializeRoutes(router *gin.Engine) {
	router.GET("/*all", GetProxy)
	router.POST("/*all", PostProxy)
	router.DELETE("/*all", DeleteProxy)
	//router.GET("/montecito/ping", Ping)
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		println("GATEWAY REQUEST ID: " + c.GetHeader("Request-ID"))
		c.Next()
	}
}

func AuthChecker() gin.HandlerFunc {
	return func(c *gin.Context) {

		var requestUserID string
		// var requestUserRoles []string

		ctx := context.Background()
		client, err := service.FirebaseAdmin.Auth(ctx)
		if err != nil {
			log.Fatalf("error getting Auth client: %v\n", err)
		}
		if c.GetHeader("Authorization") != "" {
			token, err := client.VerifyIDToken(ctx, strings.Split(c.GetHeader("Authorization"), "Bearer ")[1])
			if err != nil {
				println("error verifying ID token")
				requestUserID = "null"
			} else {
				println("Decoded User ID: " + token.UID)
				requestUserID = token.UID
				// TODO: Get user roles from lacumbre
				// roles := service.GetRolesForUser(requestUserID)
				// for _, role := range roles {
				//	requestUserRoles = append(requestUserRoles, role.Role)
				// }
			}
		} else {
			println("No user token provided")
			requestUserID = "null"
		}
		println("STUB: " + requestUserID)
		// The main authentication gateway per request path
		// The requesting user's ID and roles are pulled and used below
		// Any path can also be quickly halted if not ready for prod
		c.Next()
	}
}

func GetProxy(c *gin.Context) {
	startTime := time.Now()
	requestID := uuid.New().String()
	c.Header("Request-ID", requestID)
	fmt.Println("GATEWAY REQUEST ID: " + requestID)
	// Get service to handle route
	mappedService := service.MatchRoute(strings.Split(c.Request.URL.String(), "/")[1], requestID)
	if mappedService.ID != 0 {
		// Proxy the actual request
		proxyClient := &http.Client{}
		req, _ := http.NewRequest("GET", "http://localhost"+":"+config.RinconPort+c.Request.URL.String(), nil)
		//req, _ := http.NewRequest("GET", service.URL+c.FullPath(), nil)
		req.Header.Set("Request-ID", requestID)
		req.Header.Add("Content-Type", "application/json")
		res, err := proxyClient.Do(req)
		if err != nil {
			log.Println(err.Error())
		}
		defer res.Body.Close()

		log.Println(res.Header)

		responseModel := model.Response{
			Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
			Gateway:   "Montecito v" + config.Version,
			Service:   mappedService.Name + " v" + mappedService.Version,
			Timestamp: time.Now().Format(time.RubyDate),
		}

		bodyBytes, err := io.ReadAll(res.Body)
		if err != nil {
			// Failed to decode response body
			log.Println(err.Error())
			c.JSON(http.StatusInternalServerError, model.Response{
				Status:    "ERROR",
				Ping:      strconv.FormatInt(time.Now().Sub(startTime).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   config.RinconService.Name + " v" + config.RinconService.Version,
				Timestamp: time.Now().Format(time.RubyDate),
				Data:      json.RawMessage("{\"message\": \"Failed to decode service response body: " + err.Error() + "\"}"),
			})
			return
		}
		bodyString := string(bodyBytes)
		responseModel.Data = json.RawMessage(bodyString)

		if res.StatusCode >= 200 && res.StatusCode < 300 {
			responseModel.Status = "SUCCESS"
		} else {
			responseModel.Status = "ERROR"
		}
		c.JSON(res.StatusCode, responseModel)

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
}

func PostProxy(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Montecito v" + config.Version + " is online!"})
}

func DeleteProxy(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Montecito v" + config.Version + " is online!"})
}
