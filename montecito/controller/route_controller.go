package controller

import (
	"bytes"
	"context"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"io"
	"montecito/config"
	"montecito/model"
	"montecito/service"
	"montecito/utils"
	"strconv"
	"strings"
	"time"
)

func InitializeRoutes(router *gin.Engine) {
	router.GET("/*all", GetProxy)
	router.POST("/*all", PostProxy)
	router.DELETE("/*all", DeleteProxy)
}

func CorsHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "*")
		c.Header("Access-Control-Allow-Methods", "GET,POST,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Set("startTime", time.Now())

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		utils.SugarLogger.Infoln("-------------------------------------------------------------------")
		utils.SugarLogger.Infoln(time.Now().Format("Mon Jan 02 15:04:05 MST 2006"))
		utils.SugarLogger.Infoln("REQUESTED ROUTE: " + c.Request.Host + c.Request.URL.String() + " [" + c.Request.Method + "]")
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			utils.SugarLogger.Infoln("REQUEST BODY: " + err.Error())
		} else {
			utils.SugarLogger.Infoln("REQUEST BODY: " + string(bodyBytes))
		}
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		utils.SugarLogger.Infoln("REQUEST ORIGIN: " + c.ClientIP())
		requestID := uuid.New().String()
		utils.SugarLogger.Infoln("GATEWAY REQUEST ID: " + requestID)
		c.Request.Header.Set("Request-ID", requestID)
		c.Next()
	}
}

func ResponseLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		utils.SugarLogger.Infoln("RESPONSE STATUS: " + strconv.Itoa(c.Writer.Status()))
	}
}

func MontecitoRoutes() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.String() == "/montecito/ping" {
			Ping(c)
			return
		}
		c.Next()
	}
}

func APIKeyChecker() gin.HandlerFunc {
	return func(c *gin.Context) {
		if strings.HasSuffix(c.Request.URL.String(), "/ping") {
			c.Next()
			return
		}

		apiKey := service.VerifyAPIKey(c.GetHeader("SC-API-KEY"))

		if apiKey.ID == "" {
			startTime, _ := c.Get("startTime")
			utils.SugarLogger.Errorln("INVALID API KEY")
			c.AbortWithStatusJSON(401, model.Response{
				Status:    "ERROR",
				Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   "Montecito v" + config.Version,
				Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
				Data:      json.RawMessage("{\"message\": \"StorkeCentral API Key invalid or missing!\"}"),
			})
			return
		}
		utils.SugarLogger.Infoln("API KEY: " + apiKey.ID)

		if apiKey.Expires.Before(time.Now()) {
			startTime, _ := c.Get("startTime")
			utils.SugarLogger.Errorln("API KEY EXPIRED ON " + apiKey.Expires.Format("Mon Jan 02 15:04:05 MST 2006") + "!")
			c.AbortWithStatusJSON(401, model.Response{
				Status:    "ERROR",
				Ping:      strconv.FormatInt(time.Now().Sub(startTime.(time.Time)).Milliseconds(), 10) + "ms",
				Gateway:   "Montecito v" + config.Version,
				Service:   "Montecito v" + config.Version,
				Timestamp: time.Now().Format("Mon Jan 02 15:04:05 MST 2006"),
				Data:      json.RawMessage("{\"message\": \"StorkeCentral API Key expired on " + apiKey.Expires.Format("Mon Jan 02 15:04:05 MST 2006") + "\"}"),
			})
			return
		}

		c.Next()
	}
}

func AuthChecker() gin.HandlerFunc {
	return func(c *gin.Context) {

		var requestUserID string

		ctx := context.Background()
		client, err := service.FirebaseAdmin.Auth(ctx)
		if err != nil {
			utils.SugarLogger.Fatalf("error getting Auth client: %v\n", err)
		}
		if c.GetHeader("Authorization") != "" {
			token, err := client.VerifyIDToken(ctx, strings.Split(c.GetHeader("Authorization"), "Bearer ")[1])
			if err != nil {
				utils.SugarLogger.Errorln("🚨 Failed to verify token: " + err.Error())
				requestUserID = "null"
			} else {
				utils.SugarLogger.Infoln("Decoded User ID: " + token.UID)
				requestUserID = token.UID
			}
		} else {
			utils.SugarLogger.Infoln("No user token provided")
			requestUserID = "null"
		}
		c.Set("userID", requestUserID)
		// The main authentication gateway per request path
		// The requesting user's ID and roles are pulled and used below
		// Any path can also be quickly halted if not ready for prod
		c.Next()
	}
}
