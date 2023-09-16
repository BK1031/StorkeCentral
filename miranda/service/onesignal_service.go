package service

import (
	"context"
	onesignal "github.com/OneSignal/onesignal-go-api"
	"io"
	"miranda/config"
	"miranda/utils"
)

var OneSignal *onesignal.APIClient

func InitializeOneSignal() {
	configuration := onesignal.NewConfiguration()
	OneSignal = onesignal.NewAPIClient(configuration)
}

func CreateOSNotification(notification *onesignal.Notification, userID string) {
	notification.SetAppId(config.OneSignalAppID)
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
	notification.SetAppId(config.OneSignalAppID)
	notification.SetIosBadgeCount(int32(GetUnreadNotificationCountForUser(userID)))
	notification.SetIosBadgeType("SetTo")
	notification.SetContentAvailable(true)
	notification.SetIncludePlayerIds([]string{GetPlayerIDForUser(userID)})

	appAuth := context.WithValue(context.Background(), onesignal.AppAuth, config.OneSignalApiKey)
	resp, r, err := OneSignal.DefaultApi.CreateNotification(appAuth).Notification(notification).Execute()
	if err != nil {
		utils.SugarLogger.Errorln("Error sending onesignal notification: " + err.Error())
		// print res body
		defer r.Body.Close()
		bodyBytes, _ := io.ReadAll(r.Body)
		bodyString := string(bodyBytes)
		utils.SugarLogger.Infoln("Response body: " + bodyString)
		return
	}
	utils.SugarLogger.Infoln("Sent onesignal notification: " + resp.GetId())
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "OneSignal notification "+resp.GetId()+" sent successfully!")
}
