package controller

import (
	"context"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"strings"
	"tepusquet/service"
)

func InitializeRoutes(router *gin.Engine) {
	router.GET("/tepusquet/ping", Ping)
	router.POST("/users/credentials/:userID", SetCredentialForUser)
	router.GET("/users/courses/:userID", GetAllCoursesForUser)
	router.GET("/users/courses/:userID/:quarter", GetCoursesForUserForQuarter)
	router.GET("/users/courses/:userID/fetch/:quarter", FetchCoursesForUserForQuarter)
	router.DELETE("/users/courses/:userID/:quarter/:courseID", RemoveCourseForUserForQuarter)
	router.GET("/users/schedule/:userID/:quarter", GetScheduleForUserForQuarter)
	router.POST("/users/schedule/:userID/:quarter", SetScheduleForUserForQuarter)
	router.DELETE("/users/schedule/:userID/:quarter", RemoveScheduleForUserForQuarter)
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
		//var requestUserRoles []string

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
				//roles := service.GetRolesForUser(requestUserID)
				//for _, role := range roles {
				//	requestUserRoles = append(requestUserRoles, role.Role)
				//}
			}
		} else {
			println("No user token provided")
			requestUserID = "null"
		}
		// The main authentication gateway per request path
		// The requesting user's ID and roles are pulled and used below
		// Any path can also be quickly halted if not ready for prod
		if c.FullPath() == "/users/credentials/:userID" {
			// Modifying a user's credentials requires the requesting user to have
			// a matching user ID
			if c.Request.Method == "POST" {
				if requestUserID != c.Param("userID") {
					c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "You do not have permission to edit this resource"})
				}
			}
		}
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
