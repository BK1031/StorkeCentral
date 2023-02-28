package model

type NotificationData struct {
	NotificationID string `json:"notification_id"`
	Key            string `json:"key"`
	Value          string `json:"value"`
}

func (NotificationData) TableName() string {
	return "notification_data"
}
