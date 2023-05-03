package service

import (
	"context"
	"fmt"
	"miranda/config"
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
		_, _ = Discord.ChannelMessageSend(config.DiscordChannel, ":rotating_light: Failed to send OneSignal notification! Check logs for more info.")
		fmt.Fprintf(os.Stderr, "Error when calling `DefaultApi.CreateNotification``: %v\n", err)
		fmt.Fprintf(os.Stderr, "Full HTTP response: %v\n", r)
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Successfully sent OneSignal notification: "+resp.Id)
	fmt.Fprintf(os.Stdout, "Response from `DefaultApi.CreateNotification`: %v\n", resp)
}
