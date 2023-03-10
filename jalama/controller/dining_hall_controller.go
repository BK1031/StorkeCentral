package controller

import (
	"github.com/gin-gonic/gin"
	"jalama/service"
	"net/http"
)

func GetAllDiningHalls(c *gin.Context) {
	result := service.GetAllDiningHalls()
	c.JSON(http.StatusOK, result)
}

func GetDiningHall(c *gin.Context) {
	result := service.GetDiningHall(c.Param("diningHallID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No dining hall found with given id: " + c.Param("diningHallID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func FetchAllDiningHalls(c *gin.Context) {
	result := service.FetchAllDiningHalls()
	c.JSON(http.StatusOK, result)
}
