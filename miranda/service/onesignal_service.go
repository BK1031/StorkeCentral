package service

import (
	"context"
	"miranda/config"
	"miranda/utils"
	"os"

	onesignal "github.com/OneSignal/onesignal-go-api"
)

var OneSignal *onesignal.APIClient

func InitializeOneSignal() {
	configuration := onesignal.NewConfiguration()
	OneSignal = onesignal.NewAPIClient(configuration)
}

func CreateOSNotification(notification *onesignal.Notification) {
	notification.SetPriority(10)
	notification.SetIosBadgeCount(1)
	notification.SetIosBadgeType("Increase")
	appAuth := context.WithValue(context.Background(), onesignal.AppAuth, config.OneSignalApiKey)

	resp, r, err := OneSignal.DefaultApi.CreateNotification(appAuth).Notification(*notification).Execute()

	if err != nil {
		utils.SugarLogger.Errorln(os.Stderr, "Error when calling `DefaultApi.CreateNotification``: %v\n", err)
		utils.SugarLogger.Errorln(os.Stderr, "Full HTTP response: %v\n", r)
	}
	utils.SugarLogger.Infoln(os.Stdout, "Response from `DefaultApi.CreateNotification`: %v\n", resp)
}
