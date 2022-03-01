package controller

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"rincon/service"
)

func GetAllServiceStatus(c *gin.Context)  {
	returnList := []gin.H{}
	services := service.GetAllServices()
	if len(services) == 0 {
		c.JSON(http.StatusNotFound, returnList)
		return
	}
	for i, s := range services {
		println(i, s.Name)
		returnList = append(returnList, service.GetServiceStatus(s))
	}
	c.JSON(http.StatusOK, returnList)
}

func GetServiceStatus(c *gin.Context) {
	returnList := []gin.H{}
	services := service.GetServiceByName(c.Param("name"))
	if len(services) == 0 {
		c.JSON(http.StatusNotFound, returnList)
		return
	}
	for i, s := range services {
		println(i, s.Name)
		returnList = append(returnList, service.GetServiceStatus(s))
	}
	c.JSON(http.StatusOK, returnList)
}
