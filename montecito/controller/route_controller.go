package controller

import (
	"bytes"
	"context"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"io"
	"log"
	"montecito/service"
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

func CorsHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "*")
		c.Header("Access-Control-Allow-Methods", "GET,POST,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		println("-------------------------------------------------------------------")
		println(time.Now().Format("Mon Jan 02 15:04:05 MST 2006"))
		println("REQUESTED ROUTE: " + c.Request.Host + c.Request.URL.String() + " [" + c.Request.Method + "]")
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			println("REQUEST BODY: " + err.Error())
		} else {
			println("REQUEST BODY: " + string(bodyBytes))
		}
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		println("REQUEST ORIGIN: " + c.ClientIP())
		requestID := uuid.New().String()
		println("GATEWAY REQUEST ID: " + requestID)
		c.Request.Header.Set("Request-ID", requestID)
		c.Next()
	}
}

func ResponseLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		println("RESPONSE STATUS: " + strconv.Itoa(c.Writer.Status()))
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
