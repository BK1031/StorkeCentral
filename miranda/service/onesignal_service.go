package service

import (
	"context"
	onesignal "github.com/OneSignal/onesignal-go-api"
	"miranda/config"
	"miranda/utils"
)

var OneSignal *onesignal.APIClient

func InitializeOneSignal() {
	configuration := onesignal.NewConfiguration()
	OneSignal = onesignal.NewAPIClient(configuration)
}

func CreateOSNotification(notification *onesignal.Notification, userID string) {
	notification.SetPriority(10)
	notification.SetIosBadgeType("None")
	if userID != "" {
		notification.SetIosBadgeCount(int32(GetUnreadNotificationCountForUser(userID)))
		notification.SetIosBadgeType("SetTo")
	}

	appAuth := context.WithValue(context.Background(), onesignal.AppAuth, config.OneSignalApiKey)
	resp, _, err := OneSignal.DefaultApi.CreateNotification(appAuth).Notification(*notification).Execute()
	if err != nil {
		utils.SugarLogger.Errorln("Error sending onesignal notification: " + err.Error())
		return
	}
	utils.SugarLogger.Infoln("Sent onesignal notification: " + resp.GetId())
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "OneSignal notification "+resp.GetId()+" sent successfully!")
}

func UpdateUserBadgeCount(userID string) {
	notification := onesignal.Notification{}
	notification.SetIosBadgeCount(int32(GetUnreadNotificationCountForUser(userID)))
	notification.SetIosBadgeType("SetTo")
	notification.SetContentAvailable(false)

	appAuth := context.WithValue(context.Background(), onesignal.AppAuth, config.OneSignalApiKey)
	resp, _, err := OneSignal.DefaultApi.CreateNotification(appAuth).Notification(notification).Execute()
	if err != nil {
		utils.SugarLogger.Errorln("Error sending onesignal notification: " + err.Error())
		return
	}
	utils.SugarLogger.Infoln("Sent onesignal notification: " + resp.GetId())
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "OneSignal notification "+resp.GetId()+" sent successfully!")
}
