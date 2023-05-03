package service

import (
	"strconv"
	"strings"
	"tepusquet/config"
	"tepusquet/model"
	"time"
)

func GetUpNextForUserForQuarter(userID string, quarter string) []model.UserUpNext {
	var upNext []model.UserUpNext
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&upNext)
	if result.Error != nil {
	}
	return upNext
}

func SetUpNextForUserForQuarter(upNext []model.UserUpNext) error {
	for _, s := range upNext {
		if result := DB.Create(&s); result.Error != nil {
			return result.Error
		}
	}
	return nil
}

func RemoveUpNextForUserForQuarter(userID string, quarter string) {
	DB.Where("user_id = ? AND quarter = ?", userID, quarter).Delete(&model.UserUpNext{})
}

func FetchUpNextForAllUsers() {
	var users []string
	result := DB.Select("DISTINCT user_id").Where("quarter = ?", config.CurrentQuarter).Find(&model.UserScheduleItem{}).Pluck("user_id", &users)
	if result.Error != nil {
	}
	_, _ = Discord.ChannelMessageSend(config.DiscordChannel, "Found "+strconv.Itoa(len(users))+" users with schedules this quarter")
	for _, id := range users {
		FetchUpNextForUserForQuarter(id, config.CurrentQuarter)
	}
}

func FetchUpNextForUserForQuarter(userID string, quarter string) {
	var upNext []model.UserUpNext
	var scheduleItems []model.UserScheduleItem
	result := DB.Where("user_id = ? AND quarter = ?", userID, quarter).Find(&scheduleItems)
	if result.Error != nil {
	}
	t := time.Now()
	currentTime := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())

	for _, s := range scheduleItems {
		days := convertDays(s.Days)
		for _, day := range days {
			if day == int(t.Weekday()) {
				openTimeSegments := strings.Split(s.StartTime, ":")
				hour, _ := strconv.ParseInt(openTimeSegments[0], 10, 16)
				minute, _ := strconv.ParseInt(openTimeSegments[1], 10, 16)
				startTime := currentTime.Add(time.Hour*time.Duration(hour) + time.Minute*time.Duration(minute))
				closeTimeSegments := strings.Split(s.EndTime, ":")
				hour, _ = strconv.ParseInt(closeTimeSegments[0], 10, 16)
				minute, _ = strconv.ParseInt(closeTimeSegments[1], 10, 16)
				endTime := currentTime.Add(time.Hour*time.Duration(hour) + time.Minute*time.Duration(minute))
				upNextItem := model.UserUpNext{
					UserID:    userID,
					CourseID:  s.CourseID,
					Title:     s.Title,
					StartTime: startTime.UTC(),
					EndTime:   endTime.UTC(),
					Quarter:   quarter,
					CreatedAt: time.Time{},
				}
				upNext = append(upNext, upNextItem)
			}
		}
	}
	RemoveUpNextForUserForQuarter(userID, quarter)
	err := SetUpNextForUserForQuarter(upNext)
	if err != nil {
		return
	}
}

// Helper function to convert the days string that we get from GOLD to
// a list of ints to represent the days of the week
func convertDays(days string) []int {
	var daysList []int
	for _, day := range days {
		switch day {
		case 'M':
			daysList = append(daysList, 1)
		case 'T':
			daysList = append(daysList, 2)
		case 'W':
			daysList = append(daysList, 3)
		case 'R':
			daysList = append(daysList, 4)
		case 'F':
			daysList = append(daysList, 5)
		case 'S':
			daysList = append(daysList, 6)
		case 'U':
			daysList = append(daysList, 7)
		}
	}
	return daysList
}
