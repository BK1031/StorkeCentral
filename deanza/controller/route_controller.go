package controller

import (
	"context"
	"deanza/service"
	"deanza/utils"
	"github.com/gin-gonic/gin"
	"log"
	"strings"
)

func InitializeRoutes(router *gin.Engine) {
	router.GET("/deanza/ping", Ping)
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		utils.SugarLogger.Infoln("GATEWAY REQUEST ID: " + c.GetHeader("Request-ID"))
		c.Next()
	}
}

func AuthChecker() gin.HandlerFunc {
	return func(c *gin.Context) {

		var requestUserID string
		//var requestUserRoles []string

		ctx := context.Background()
		client, err := service.FirebaseAdmin.Auth(ctx)
		if err != nil {
			log.Fatalf("error getting Auth client: %v\n", err)
		}
		if c.GetHeader("Authorization") != "" {
			token, err := client.VerifyIDToken(ctx, strings.Split(c.GetHeader("Authorization"), "Bearer ")[1])
			if err != nil {
				utils.SugarLogger.Errorln("error verifying ID token")
				requestUserID = "null"
			} else {
				utils.SugarLogger.Infoln("Decoded User ID: " + token.UID)
				requestUserID = token.UID
				// TODO: Get user roles from lacumbre
				//roles := service.GetRolesForUser(requestUserID)
				//for _, role := range roles {
				//	requestUserRoles = append(requestUserRoles, role.Role)
				//}
			}
		} else {
			utils.SugarLogger.Infoln("No user token provided")
			requestUserID = "null"
		}
		println("STUB: " + requestUserID)
		// The main authentication gateway per request path
		// The requesting user's ID and roles are pulled and used below
		// Any path can also be quickly halted if not ready for prod
		c.Next()
	}
}

// Holy fuck why is there no contains
// function for arrays in this language
// TODO: upgrade to binary search
func contains(s []string, element string) bool {
	for _, i := range s {
		if i == element {
			return true
		}
	}
	return false
}
