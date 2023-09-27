package model

type SubscribedUpNext struct {
	UserID           string       `json:"user_id"`
	SubscribedUserID string       `json:"subscribed_user_id"`
	UpNext           []UserUpNext `gorm:"-" json:"up_next"`
}

func (SubscribedUpNext) TableName() string {
	return "subscribed_up_next"
}
