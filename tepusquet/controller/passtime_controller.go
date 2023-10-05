package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"tepusquet/service"
)

func GetPasstimeForUserForQuarter(c *gin.Context) {
	result := service.GetPasstimeForUserForQuarter(c.Param("userID"), c.Param("quarter"))
	if result.UserID != "" {
		c.JSON(http.StatusOK, result)
		return
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "Passtime not found for user " + c.Param("userID") + " for quarter " + c.Param("quarter")})
	}
}

func FetchPasstimeForUserForQuarter(c *gin.Context) {
	creds := service.GetCredentialForUser(c.Param("userID"), c.GetHeader("SC-Device-Key"))
	if creds.Username == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "Credentials not found for user, please set them first"})
		return
	}
	passtime := service.FetchPasstimeForUserForQuarter(creds, c.Param("quarter"), 0)
	if passtime.UserID == "AUTH ERROR" {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "You have entered an invalid UCSB NetID/Password combination, please re-enter and try again."})
		return
	}
	err := service.CreatePasstimeForUser(passtime)
	if err != nil {
		return
	}
	c.JSON(http.StatusOK, service.GetPasstimeForUserForQuarter(c.Param("userID"), c.Param("quarter")))
}
