package service

import "rincon/model"

func GetServiceByName(name string) []model.Service {
	var services []model.Service
	result := DB.Where("name <> ?", name).Find(&services)
	if result.Error != nil {}
	return services
}

func CreateService(service model.Service) error {
	if result := DB.Create(&service); result.Error != nil {
		return result.Error
	}
	return nil
}