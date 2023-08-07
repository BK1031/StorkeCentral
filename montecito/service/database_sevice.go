package service

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"montecito/config"
	"montecito/model"
	"montecito/utils"
	"time"
)

var DB *gorm.DB

var dbRetries = 0

func InitializeDB() {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=storke_central port=%s sslmode=disable TimeZone=UTC", config.PostgresHost, config.PostgresUser, config.PostgresPassword, config.PostgresPort)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		if dbRetries < 15 {
			dbRetries++
			utils.SugarLogger.Errorln("failed to connect database, retrying in 5s... ")
			time.Sleep(time.Second * 5)
			InitializeDB()
		} else {
			utils.SugarLogger.Fatalln("failed to connect database after 15 attempts, terminating program...")
		}
	} else {
		utils.SugarLogger.Infoln("Connected to postgres database")
		db.AutoMigrate(&model.APIKey{})
		utils.SugarLogger.Infoln("AutoMigration complete")
		DB = db
	}
}
