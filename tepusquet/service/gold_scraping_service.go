package service

import (
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
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)
	err := rod.Try(func() {
		page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
		page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
		page.MustElement("#pageContent_loginButton").MustClick()
		page.Race().Element("#MainForm > header > div > div > div > div > div.search-bundle-wrapper.header-functions.col-sm-6.col-md-5.col-md-offset-1.col-lg-4.col-lg-offset-3.hidden-xs > div > div:nth-child(4) > a").MustHandle(func(e *rod.Element) {
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

func FetchCoursesForUserForQuarter(credential model.UserCredential, quarter string, retry int) []model.UserCourse {
	maxRetries := 25
	var courses []model.UserCourse
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)

	err := rod.Try(func() {
		page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
		page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
		page.MustElement("#pageContent_loginButton").MustClick()

		page.Race().Element("#MainForm > header > div > div > div > div > div.search-bundle-wrapper.header-functions.col-sm-6.col-md-5.col-md-offset-1.col-lg-4.col-lg-offset-3.hidden-xs > div > div:nth-child(4) > a").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
			page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/StudentSchedule.aspx")
			page.MustWaitIdle()
			utils.SugarLogger.Infoln("Found schedule grid")
			page.MustElement("#ctl00_pageContent_quarterDropDown")
			// $('#ctl00_pageContent_quarterDropDown option[value="20232"]').attr("selected", "selected").change();
			page.Eval("$('#ctl00_pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
			page.MustElement("#ctl00_pageContent_ScheduleGrid")
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
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchCoursesForUserForQuarter(credential, quarter, retry)
		}
	}
	return courses
}

func FetchFinalsForUserForQuarter(credential model.UserCredential, quarter string, retry int) []model.UserFinal {
	maxRetries := 25
	var finals []model.UserFinal
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)

	err := rod.Try(func() {
		page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
		page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
		page.MustElement("#pageContent_loginButton").MustClick()

		page.Race().Element("#MainForm > header > div > div > div > div > div.search-bundle-wrapper.header-functions.col-sm-6.col-md-5.col-md-offset-1.col-lg-4.col-lg-offset-3.hidden-xs > div > div:nth-child(4) > a").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
			page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/StudentSchedule.aspx")
			page.MustWaitIdle()
			utils.SugarLogger.Infoln("Found schedule grid")
			page.MustElement("#ctl00_pageContent_quarterDropDown")
			// $('#ctl00_pageContent_quarterDropDown option[value="20232"]').attr("selected", "selected").change();
			page.Eval("$('#ctl00_pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
			page.MustElement("#ctl00_pageContent_ScheduleGrid")
			page.MustWaitIdle()
			utils.SugarLogger.Infoln("Selected quarter " + quarter)
			finalNameElements := page.MustElements("div.col-sm-5.col-xs-12")
			utils.SugarLogger.Infoln("Found " + strconv.Itoa(len(finalNameElements)) + " final names")
			for _, courseElement := range finalNameElements {
				if courseElement.MustText() != "" {
					utils.SugarLogger.Infoln(courseElement.MustText())
				}
			}
			finalElements := page.MustElements("div.col-sm-7.col-xs-12")
			utils.SugarLogger.Infoln("Found " + strconv.Itoa(len(finalElements)) + " finals")
			for _, courseElement := range finalElements {
				if courseElement.MustText() != "" {
					utils.SugarLogger.Infoln(courseElement.MustText())
					// Monday, December 11, 2023 12:00 PM - 3:00 PM
					finalString := courseElement.MustText()
					finalMap := strings.Split(finalString, ", ")
					monthday := finalMap[1]
					year := strings.Split(finalMap[2], " ")[0]
					times := strings.Replace(finalMap[2], year+" ", "", 1)
					startTime := strings.Split(times, " - ")[0]
					endTime := strings.Split(times, " - ")[1]

					currentZone, _ := time.Now().Zone()

					// December 11, 2023 12:00 PM
					startParseString := monthday + ", " + year + " " + startTime
					startDate, _ := time.Parse("January 02, 2006 3:04 PM (MST)", startParseString+" ("+currentZone+")")
					dateZone, _ := startDate.Zone()
					// Really fucking cringe daylight saving handler
					if currentZone == "PDT" && dateZone == "PST" {
						// Add 1 hour to account for shift out of daylight savings
						startDate = startDate.Add(time.Hour * 1)
					} else if currentZone == "PST" && dateZone == "PDT" {
						// Subtract 1 hour to account for shift into daylight savings
						startDate = startDate.Add(-time.Hour * 1)
					}
					utils.SugarLogger.Infoln(startDate.String())

					// December 11, 2023 3:00 PM
					endParseString := monthday + ", " + year + " " + endTime
					endDate, _ := time.Parse("January 02, 2006 3:04 PM (MST)", endParseString+" ("+currentZone+")")
					dateZone, _ = endDate.Zone()
					// Really fucking cringe daylight saving handler
					if currentZone == "PDT" && dateZone == "PST" {
						// Add 1 hour to account for shift out of daylight savings
						endDate = endDate.Add(time.Hour * 1)
					} else if currentZone == "PST" && dateZone == "PDT" {
						// Subtract 1 hour to account for shift into daylight savings
						endDate = endDate.Add(-time.Hour * 1)
					}
					utils.SugarLogger.Infoln(endDate.String())
				}
			}
		}).Element("#pageContent_errorLabel > ul").MustHandle(func(e *rod.Element) {
			// Wrong username/password
			utils.SugarLogger.Infoln(e.MustText())
			finals = append(finals, model.UserFinal{
				UserID: "AUTH ERROR",
			})
		}).MustDo()
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchFinalsForUserForQuarter(credential, quarter, retry)
		}
	}
	return finals
}

func FetchPasstimeForUserForQuarter(credential model.UserCredential, quarter string, retry int) model.UserPasstime {
	maxRetries := 25
	var passtime model.UserPasstime
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)

	err := rod.Try(func() {
		page.MustElement("#pageContent_userNameText").MustInput(credential.Username)
		page.MustElement("#pageContent_passwordText").MustInput(credential.Password)
		page.MustElement("#pageContent_loginButton").MustClick()

		page.Race().Element("#MainForm > header > div > div > div > div > div.search-bundle-wrapper.header-functions.col-sm-6.col-md-5.col-md-offset-1.col-lg-4.col-lg-offset-3.hidden-xs > div > div:nth-child(4) > a").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
			page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/RegistrationInfo.aspx")
			page.MustWaitIdle()
			page.MustElement("#pageContent_quarterDropDown")
			page.Eval("$('#pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
			page.MustWaitIdle()
			utils.SugarLogger.Infoln("Selected quarter " + quarter)
			//time.Sleep(300 * time.Millisecond)

			currentZone, _ := time.Now().Zone()

			passOne := page.MustElement("#pageContent_PassOneLabel")
			utils.SugarLogger.Infoln("Found Pass 1 Time: " + passOne.MustText())
			passOneArray := strings.Split(passOne.MustText(), " - ")
			passOneStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passOneArray[0]+" ("+currentZone+")")
			passOneEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passOneArray[1]+" ("+currentZone+")")
			passOneStart = HandleDaylightSavings(passOneStart)
			passOneEnd = HandleDaylightSavings(passOneEnd)
			utils.SugarLogger.Infoln(passOneStart)
			utils.SugarLogger.Infoln(passOneEnd)

			passTwo := page.MustElement("#pageContent_PassTwoLabel")
			utils.SugarLogger.Infoln("Found Pass 2 Time: " + passTwo.MustText())
			passTwoArray := strings.Split(passTwo.MustText(), " - ")
			passTwoStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passTwoArray[0]+" ("+currentZone+")")
			passTwoEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passTwoArray[1]+" ("+currentZone+")")
			passTwoStart = HandleDaylightSavings(passTwoStart)
			passTwoEnd = HandleDaylightSavings(passTwoEnd)
			utils.SugarLogger.Infoln(passTwoStart)
			utils.SugarLogger.Infoln(passTwoEnd)

			passThree := page.MustElement("#pageContent_PassThreeLabel")
			utils.SugarLogger.Infoln("Found Pass 3 Time: " + passThree.MustText())
			passThreeArray := strings.Split(passThree.MustText(), " - ")
			passThreeStart, _ := time.Parse("1/2/2006 3:04 PM (MST)", passThreeArray[0]+" ("+currentZone+")")
			passThreeEnd, _ := time.Parse("1/2/2006 3:04 PM (MST)", passThreeArray[1]+" ("+currentZone+")")
			passThreeStart = HandleDaylightSavings(passThreeStart)
			passThreeEnd = HandleDaylightSavings(passThreeEnd)
			utils.SugarLogger.Infoln(passThreeStart)
			utils.SugarLogger.Infoln(passThreeEnd)

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
			utils.SugarLogger.Infoln(e.MustText())
			passtime.UserID = "AUTH ERROR"
		}).MustDo()
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchPasstimeForUserForQuarter(credential, quarter, retry)
		}
	}
	return passtime
}

// HandleDaylightSavings is a really fucking cringe daylight savings handler that adjusts
// the input time struct based on its assigned zone and the current system zone.
func HandleDaylightSavings(input time.Time) time.Time {
	currentZone, _ := time.Now().Zone()
	inputZone, _ := input.Zone()
	if currentZone == "PDT" && inputZone == "PST" {
		// Add 1 hour to account for shift out of daylight savings
		return input.Add(time.Hour * 1)
	} else if currentZone == "PST" && inputZone == "PDT" {
		// Subtract 1 hour to account for shift into daylight savings
		return input.Add(-time.Hour * 1)
	}
	return input
}
