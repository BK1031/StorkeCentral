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
	dsn := fmt.Sprintf("host=localhost user=%s password=%s dbname=storke_central port=5432 sslmode=disable TimeZone=UTC", config.PostgresUser, config.PostgresPassword)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		//panic("failed to connect database")
	}
	println("Connected to postgres database")
	db.AutoMigrate(&model.Service{}, &model.Route{})
	println("AutoMigration complete")
	DB = db
}