package controller

import "github.com/gin-gonic/gin"

func InitializeRoutes(router *gin.Engine)  {
	router.GET("/lacumbre/ping", Ping)
	router.GET("/users", GetAllUsers)
	router.GET("/users/:userID", GetUserByID)
	router.POST("/users", CreateUser)
	router.GET("/users/:userID/roles", GetRolesForUser)
	router.POST("/users/:userID/roles", SetRolesForUser)
	router.GET("/users/:userID/friends", GetFriendsForUser)
	router.POST("/users/:userID/friends", CreateFriendRequest)
	router.DELETE("/users/:userID/friends/:requestID", DeleteFriendRequest)
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		println("GATEWAY REQUEST ID: " + c.GetHeader("Request-ID"))
		c.Next()
	}
}

func AuthChecker() gin.HandlerFunc {
	return func(c *gin.Context) {

		c.Next()
	}
}