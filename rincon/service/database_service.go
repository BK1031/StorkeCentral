package service

import (
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"os"
	"rincon/config"
	"rincon/model"
	"time"
)

var DB *gorm.DB

var retries = 0

func InitializeDB() {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=storke_central port=%s sslmode=disable TimeZone=UTC", config.PostgresHost, config.PostgresUser, config.PostgresPassword, config.PostgresPort)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		if retries < 15 {
			retries++
			println("failed to connect database, retrying in 5s... ")
			time.Sleep(time.Second * 5)
			InitializeDB()
		} else {
			println("failed to connect database after 15 attempts, terminating program...")
			os.Exit(100)
		}
	} else {
		println("Connected to postgres database")
		db.AutoMigrate(&model.Service{}, &model.Route{})
		println("AutoMigration complete")
		DB = db
	}
}