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
	c.JSON(http.StatusOK, result)
}

func FetchAllDiningHalls(c *gin.Context) {
	result := service.FetchAllDiningHalls()
	c.JSON(http.StatusOK, result)
}
