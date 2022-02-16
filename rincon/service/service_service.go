package service

import "rincon/model"


func GetAllServices() []model.Service {
	var services []model.Service
	result := DB.Find(&services)
	if result.Error != nil {}
	return services
}

func GetServiceByID(id int) model.Service {
	var service model.Service
	result := DB.Where("id = ?", id).Find(&service)
	if result.Error != nil {}
	return service
}

func GetServiceByName(name string) []model.Service {
	var services []model.Service
	result := DB.Where("UPPER(name) = UPPER(?)", name).Find(&services)
	if result.Error != nil {}
	return services
}

func CreateService(service model.Service) error {
	if result := DB.Create(&service); result.Error != nil {
		return result.Error
	}
	return nil
}