package service

type MirandaNotification struct {
	ID         string        `json:"id"`
	UserID     string        `json:"user_id"`
	Sender     string        `json:"sender"`
	Title      string        `json:"title"`
	Body       string        `json:"body"`
	PictureUrl string        `json:"picture_url"`
	LaunchUrl  string        `json:"launch_url"`
	Route      string        `json:"route"`
	Priority   string        `json:"priority"`
	Push       bool          `json:"push"`
	Read       bool          `json:"read"`
	Data       []interface{} `json:"data"`
}

func SendMirandaNotification(mirandaBody MirandaNotification) {
	// TODO: Make this actually get the correct miranda dns value

}
