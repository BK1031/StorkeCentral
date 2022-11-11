package controller

import (
	"arguello/service"
	"github.com/gin-gonic/gin"
	"net/http"
)

func GetAllBuildings(c *gin.Context) {
	result := service.GetAllBuildings()
	c.JSON(http.StatusOK, result)
}

func GetBuildingByID(c *gin.Context) {
	result := service.GetBuildingByID(c.Param("buildingID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No building found with given id: " + c.Param("buildingID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}
