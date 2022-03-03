package service

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"rincon/config"
	"rincon/model"
)

var DB *gorm.DB

func InitializeDB() {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=storke_central port=%s sslmode=disable TimeZone=UTC", config.PostgresHost, config.PostgresUser, config.PostgresPassword, config.PostgresPort)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		//panic("failed to connect database")
	} else {
		println("Connected to postgres database")
		db.AutoMigrate(&model.Service{}, &model.Route{})
		println("AutoMigration complete")
		DB = db
	}
}