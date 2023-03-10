package controller

import (
	"github.com/gin-gonic/gin"
	"jalama/service"
	"net/http"
)

func FetchAllMealsForDay(c *gin.Context) {
	result := service.FetchAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}
