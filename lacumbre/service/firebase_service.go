package service

import (
	"context"
	"encoding/base64"
	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
	"lacumbre/config"
	"log"
	"time"
)

var FirebaseAdmin *firebase.App

func InitializeFirebase() {
	decoded, err := base64.StdEncoding.DecodeString(config.FirebaseServiceAccountEncoded)
	if err != nil {
		log.Fatalf("Error decoding service account: %v\n", err)
	}
	ctx := context.Background()
	conf := &firebase.Config{
		DatabaseURL: "https://storke-central.firebaseio.com",
		ProjectID:   "storke-central",
	}
	opt := option.WithCredentialsJSON(decoded)
	app, err := firebase.NewApp(ctx, conf, opt)
	if err != nil {
		log.Fatalln("Error initializing app:", err)
	}
	FirebaseAdmin = app
	FirebaseDBTest()
}

func FirebaseDBTest() {
	ctx := context.Background()
	client, err := FirebaseAdmin.Firestore(ctx)
	if err != nil {
		log.Printf("An error has occurred: %s", err)
	}
	client.Collection("testing").Add(ctx, map[string]interface{}{
		"message":   config.Service.Name + " v" + config.Version + " is online!",
		"env":       config.Env,
		"timestamp": time.Now().String(),
	})
}
