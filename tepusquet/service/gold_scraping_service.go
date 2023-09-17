package service

import (
	"fmt"
	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/devices"
	"github.com/go-rod/rod/lib/launcher"
	"strconv"
	"strings"
	"tepusquet/model"
	"tepusquet/utils"
	"time"
)

func VerifyCredential(credential model.UserCredential, retry int) bool {
	maxRetries := 25
	validCredential := false
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustEmulate(devices.LaptopWithHiDPIScreen)
	err := rod.Try(func() {
		page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
		page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
		page.MustElement("#pageContent_loginButton").MustClick()
		page.Race().Element("#MainForm > header > div > div > div > div > div.search-bundle-wrapper.header-functions.col-sm-6.col-md-5.col-md-offset-1.col-lg-4.col-lg-offset-3.hidden-xs > div > div:nth-child(4) > a > div").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
			validCredential = true
		}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln(e.MustText())
		}).MustDo()
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return VerifyCredential(credential, retry)
		} else {
			return false
		}
	}
	return validCredential
}

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

func FetchPasstimeForUserForQuarter(credential model.UserCredential, quarter string) model.UserPasstime {
	var passtime model.UserPasstime
	path, _ := launcher.LookPath()
	url := launcher.New().Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
	page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
	page.MustElement("#pageContent_loginButton").MustClick()

	page.Race().Element("#Li0 > a").MustHandle(func(e *rod.Element) {
		println("Logged in successfully as " + credential.Username + "@ucsb.edu")
		page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/RegistrationInfo.aspx")
		page.MustWaitIdle()
		page.Eval("$('#pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
		page.MustWaitIdle()
		println("Selected quarter " + quarter)
		//time.Sleep(300 * time.Millisecond)

		zone, _ := time.Now().Zone()

		passOne := page.MustElement("#pageContent_PassOneLabel")
		println("Found Pass 1 Time: " + passOne.MustText())
		passOneArray := strings.Split(passOne.MustText(), " - ")
		passOneStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passOneArray[0]+" ("+zone+")")
		passOneEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passOneArray[1]+" ("+zone+")")
		fmt.Println(passOneStart)
		fmt.Println(passOneEnd)

		passTwo := page.MustElement("#pageContent_PassTwoLabel")
		println("Found Pass 2 Time: " + passTwo.MustText())
		passTwoArray := strings.Split(passTwo.MustText(), " - ")
		passTwoStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passTwoArray[0]+" ("+zone+")")
		passTwoEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passTwoArray[1]+" ("+zone+")")
		fmt.Println(passTwoStart)
		fmt.Println(passTwoEnd)

		passThree := page.MustElement("#pageContent_PassThreeLabel")
		println("Found Pass 3 Time: " + passThree.MustText())
		passThreeArray := strings.Split(passThree.MustText(), " - ")
		passThreeStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passThreeArray[0]+" ("+zone+")")
		passThreeEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passThreeArray[1]+" ("+zone+")")
		fmt.Println(passThreeStart)
		fmt.Println(passThreeEnd)

		passtime.UserID = credential.UserID
		passtime.Quarter = quarter
		passtime.PassOneStart = passOneStart
		passtime.PassOneEnd = passOneEnd
		passtime.PassTwoStart = passTwoStart
		passtime.PassTwoEnd = passTwoEnd
		passtime.PassThreeStart = passThreeStart
		passtime.PassThreeEnd = passThreeEnd
	}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
		// Wrong username/password
		println(e.MustText())
		passtime.UserID = "AUTH ERROR"
	}).MustDo()
	return passtime
}
