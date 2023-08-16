package service

import (
	"arguello/model"
	"arguello/utils"
)

func GetAllBuildings() []model.Building {
	var buildings []model.Building
	result := DB.Find(&buildings)
	if result.Error != nil {
	}
	return buildings
}

func GetBuildingByID(buildingID string) model.Building {
	var building model.Building
	result := DB.Where("id = ?", buildingID).Find(&building)
	if result.Error != nil {
	}
	return building
}

func CreateBuilding(building model.Building) error {
	if DB.Where("id = ?", building.ID).Updates(&building).RowsAffected == 0 {
		utils.SugarLogger.Infoln("New building created with id: " + building.ID)
		if result := DB.Create(&building); result.Error != nil {
			return result.Error
		}
	} else {
		utils.SugarLogger.Infoln("Building with id: " + building.ID + " has been updated!")
	}
	return nil
}
