package service

import (
	"rincon/config"
	"rincon/model"
)

func GetAllRoutes() []model.Route {
	var routes []model.Route
	result := DB.Order("route desc").Find(&routes)
	if result.Error != nil {
	}
	return routes
}

func GetRouteByID(id string) model.Route {
	var route model.Route
	result := DB.Where("route = ?", id).Find(&route)
	if result.Error != nil {
	}
	return route
}

func GetRouteByService(name string) []model.Route {
	var routes []model.Route
	result := DB.Where("UPPER(service_name) = UPPER(?)", name).Order("route desc").Find(&routes)
	if result.Error != nil {
	}
	return routes
}

func CreateRoute(route model.Route) error {
	if result := DB.Create(&route); result.Error != nil {
		return result.Error
	}
	go Discord.ChannelMessageSend(config.DiscordChannel, "New route `"+route.Route+"` registered for service "+route.ServiceName)
	return nil
}

func RemoveRoute(route model.Route) error {
	if result := DB.Delete(&route); result.Error != nil {
		return result.Error
	}
	go Discord.ChannelMessageSend(config.DiscordChannel, "Route `"+route.Route+"` removed from service "+route.ServiceName)
	return nil
}
