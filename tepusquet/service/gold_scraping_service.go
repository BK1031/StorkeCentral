package service

import (
	"github.com/go-rod/rod"
	"strconv"
	"tepusquet/model"
)

func FetchCoursesForUserForQuarter(credential model.UserCredential, quarter string) []model.UserCourse {
	var courses []model.UserCourse
	page := rod.New().NoDefaultDevice().MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
	page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
	page.MustElement("#pageContent_loginButton").MustClick()

	page.Race().Element("#Li0 > a").MustHandle(func(e *rod.Element) {
		println("Logged in successfully as " + credential.Username + "@ucsb.edu")
		page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/StudentSchedule.aspx")
		page.MustElement("#ctl00_pageContent_ScheduleGrid").MustClick()
		println("Found schedule grid")
		// TODO: Support quarters other than Fall 2021
		//page.MustElement("#ctl00_pageContent_quarterDropDown").Select([]string{`[value="20221"]`}, true, rod.SelectorTypeCSSSector)
		page.MustElement("#ctl00_pageContent_ScheduleGrid").MustClick()
		println("Selected quarter " + quarter)
		courseElements := page.MustElements("div.col-sm-3.col-xs-4")
		println("Found " + strconv.Itoa(len(courseElements)) + " courses")
		for _, courseElement := range courseElements {
			println(courseElement.MustText())
			courses = append(courses, model.UserCourse{
				UserID:   credential.UserID,
				CourseID: courseElement.MustText(),
				Quarter:  quarter,
			})
		}
	}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
		// Wrong username/password
		println(e.MustText())
		courses = append(courses, model.UserCourse{
			UserID: "AUTH ERROR",
		})
	}).MustDo()
	return courses
}
