package controller

import (
	"context"
	"github.com/gin-gonic/gin"
	"lacumbre/service"
	"log"
	"net/http"
	"strings"
)

func InitializeRoutes(router *gin.Engine) {
	router.GET("/lacumbre/ping", Ping)
	router.GET("/users", GetAllUsers)
	router.GET("/users/:userID", GetUserByID)
	router.POST("/users/:userID", CreateUser)
	router.GET("/users/:userID/roles", GetRolesForUser)
	router.POST("/users/:userID/roles", SetRolesForUser)
	router.GET("/users/:userID/friends", GetFriendsForUser)
	router.POST("/users/:userID/friends", CreateFriendRequest)
	router.DELETE("/users/:userID/friends/:requestID", DeleteFriendRequest)
	router.GET("/users/:userID/logins", GetUserLogins)
	router.POST("/users/:userID/logins", CreateUserLogin)
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
		var requestUserRoles []string

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
				roles := service.GetRolesForUser(requestUserID)
				for _, role := range roles {
					requestUserRoles = append(requestUserRoles, role.Role)
				}
			}
		} else {
			println("No user token provided")
			requestUserID = "null"
		}

		// The main authentication gateway per request path
		// The requesting user's ID and roles are pulled and used below
		// Any path can also be quickly halted if not ready for prod
		if c.FullPath() == "/users/:userID" {
			// Creating or modifying a user requires the requesting user
			// to have a matching user ID or the ADMIN role
			if c.Request.Method == "POST" {
				if requestUserID != c.Param("userID") && !contains(requestUserRoles, "ADMIN") {
					c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"message": "You do not have permission to edit this resource"})
				}
			}
		} else if c.FullPath() == "/users/:userID/roles" {
			// Modifying a user's roles requires the requesting user to have
			// a matching user ID or the ADMIN role
			if c.Request.Method == "POST" {
				if requestUserID != c.Param("userID") && !contains(requestUserRoles, "ADMIN") {
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
