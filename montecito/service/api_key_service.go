package service

import (
	"montecito/config"
	"montecito/model"
	"strings"
)

func GetAllAPIKeys() []model.APIKey {
	var apiKeys []model.APIKey
	DB.Find(&apiKeys)
	config.APIKeys = apiKeys
	return apiKeys
}

func GetAPIKeyByID(id uint) model.APIKey {
	var apiKey model.APIKey
	DB.Where("id = ?", id).Find(&apiKey)
	return apiKey
}

func CreateAPIKey(apiKey model.APIKey) error {
	if result := DB.Create(&apiKey); result.Error != nil {
		return result.Error
	}
	config.APIKeys = append(config.APIKeys, apiKey)
	return nil
}

func VerifyAPIKey(apiKey string) model.APIKey {
	var returnKey model.APIKey
	for _, key := range config.APIKeys {
		if key.ID == apiKey {
			return key
		}
	}
	return returnKey
}

func VerifyAPIKeyScopes(apiKey string, service model.Service, method string) bool {
	key := VerifyAPIKey(apiKey)
	scopes := strings.Split(key.Scopes, ",")
	for _, scope := range scopes {
		if scope == "admin" {
			return true
		}
		if method == "GET" && scope == strings.ToLower(service.Name)+"_read" {
			return true
		} else if (method == "POST" || method == "DELETE") && scope == strings.ToLower(service.Name)+"_write" {
			return true
		}
	}
	return false
}
