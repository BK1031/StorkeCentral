package controller

import (
	"github.com/gin-gonic/gin"
	"jalama/service"
	"net/http"
)

func GetAllMealsForDay(c *gin.Context) {
	result := service.GetAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}

func GetMealByID(c *gin.Context) {
	result := service.GetMealByID(c.Param("mealID"))
	if result.ID == "" {
		c.JSON(http.StatusNotFound, gin.H{"message": "No meal record found with given id: " + c.Param("mealID")})
	} else {
		c.JSON(http.StatusOK, result)
	}
}

func GetMenuForMeal(c *gin.Context) {
	result := service.GetMenuForMeal(c.Param("mealID"))
	c.JSON(http.StatusOK, result)
}

func FetchAllMealsForDay(c *gin.Context) {
	result := service.FetchAllMealsForDay(c.Param("date"))
	c.JSON(http.StatusOK, result)
}
