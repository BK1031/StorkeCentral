package service

import (
	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/launcher"
	"strconv"
	"tepusquet/model"
	"tepusquet/utils"
)

func FetchCoursesForUserForQuarter(credential model.UserCredential, quarter string) []model.UserCourse {
	var courses []model.UserCourse
	path, _ := launcher.LookPath()
	url := launcher.New().Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
	page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
	page.MustElement("#pageContent_loginButton").MustClick()

	page.Race().Element("#Li0 > a").MustHandle(func(e *rod.Element) {
		utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
		page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/StudentSchedule.aspx")
		//page.MustElement("#ctl00_pageContent_ScheduleGrid").MustClick()
		page.MustWaitIdle()
		utils.SugarLogger.Infoln("Found schedule grid")
		page.Eval("$('#ctl00_pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
		//page.MustElement("#ctl00_pageContent_ScheduleGrid").MustClick()
		page.MustWaitIdle()
		utils.SugarLogger.Infoln("Selected quarter " + quarter)
		courseElements := page.MustElements("div.col-sm-3.col-xs-4")
		utils.SugarLogger.Infoln("Found " + strconv.Itoa(len(courseElements)) + " courses")
		for _, courseElement := range courseElements {
			utils.SugarLogger.Infoln(courseElement.MustText())
			courses = append(courses, model.UserCourse{
				UserID:   credential.UserID,
				CourseID: courseElement.MustText(),
				Quarter:  quarter,
			})
		}
	}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
		// Wrong username/password
		utils.SugarLogger.Infoln(e.MustText())
		courses = append(courses, model.UserCourse{
			UserID: "AUTH ERROR",
		})
	}).MustDo()
	return courses
}
