package controller

import (
	"github.com/gin-gonic/gin"
	"lacumbre/model"
	"lacumbre/service"
	"net/http"
)

func GetRolesForUser(c *gin.Context) {
	result := service.GetRolesForUser(c.Param("userID"))
	c.JSON(http.StatusOK, result)
}

func SetRolesForUser(c *gin.Context) {
	var input []model.Role
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if user := service.GetUserByID(c.Param("userID")); user.ID != "" {
		if err := service.SetRolesForUser(c.Param("userID"), input); err != nil {
			c.JSON(http.StatusInternalServerError, err)
			return
		}
		c.JSON(http.StatusOK, service.GetRolesForUser(c.Param("userID")))
	} else {
		c.JSON(http.StatusNotFound, gin.H{"message": "No user found with given id: " + c.Param("userID")})
	}
}