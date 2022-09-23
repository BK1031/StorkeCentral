package service

import (
	"github.com/go-rod/rod"
	"strconv"
)

func FetchCoursesForUser(username string, password string) []string {
	var courses []string
	page := rod.New().NoDefaultDevice().MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustElement("#pageContent_userNameText").MustInput(username)
	page.MustElement("#pageContent_passwordText").MustInput(password)
	page.MustElement("#pageContent_loginButton").MustClick()

	page.Race().Element("#Li0 > a").MustHandle(func(e *rod.Element) {
		println("Logged in successfully as " + username + "@ucsb.edu")
		page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/StudentSchedule.aspx")
		page.MustElement("#ctl00_pageContent_ScheduleGrid").MustClick()
		println("Found schedule grid")
		courseElements := page.MustElements("div.col-sm-3.col-xs-4")
		println("Found " + strconv.Itoa(len(courses)) + " courses")
		for _, courseElement := range courseElements {
			println(courseElement.MustText())
			courses = append(courses, courseElement.MustText())
		}
	}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
		// Wrong username/password
		println(e.MustText())
		courses = append(courses, e.MustText())
	}).MustDo()
	return courses
}
