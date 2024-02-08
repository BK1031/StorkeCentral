package service

import (
	"context"
	"errors"
	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/devices"
	"github.com/go-rod/rod/lib/input"
	"github.com/go-rod/rod/lib/launcher"
	"strconv"
	"strings"
	"tepusquet/model"
	"tepusquet/utils"
	"time"
)

// VerifyCredential uses a headless browser to verify a user's credentials
// Returns 0 if credentials are valid, 1 if invalid, does not attempt to complete Duo MFA
func VerifyCredential(credential model.UserCredential, retry int) int {
	status := 0
	validCredential := false
	//duoAuthenticated := false

	maxRetries := 25
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)
	err := rod.Try(func() {
		page.MustElement("#pageContent_loginButtonCurrentStudent").MustClick()
		page.MustElement("#username").MustInput(credential.Username)
		time.Sleep(100 * time.Millisecond)
		page.MustElement("#password").MustInput(credential.Password)
		page.MustElement("#fm1 > input.btn.btn-block.btn-submit").MustClick()
		// Attempt to login to UCSB SSO
		page.Race().Element("#duo_iframe").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Reached Duo MFA page for " + credential.Username + "@ucsb.edu")
			validCredential = true
		}).Element("#fm1 > div").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln(e.MustText())
		}).MustDo()

		if !validCredential {
			utils.SugarLogger.Errorln("Invalid credentials for " + credential.Username + "@ucsb.edu")
			status = 1
		}
	})
	if err != nil {
		utils.SugarLogger.Errorln("Webdriver error occurred: " + err.Error())
		if retry < maxRetries {
			retry++
			page.MustClose()
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return VerifyCredential(credential, retry)
		} else {
			return status
		}
	}
	return status
}

// LoginGOLD uses a headless browser to login to GOLD with a user's credentials
// Returns 0 if credentials are valid, 1 if invalid, 2 if Duo MFA failed
// Returns the page object if successful
func LoginGOLD(credential model.UserCredential, retry int) (int, *rod.Page) {
	status := 0
	validCredential := false
	duoAuthenticated := false

	maxRetries := 25
	path, _ := launcher.LookPath()
	url := launcher.New().
		//Headless(false).
		Bin(path).MustLaunch()
	page := rod.New().ControlURL(url).MustConnect().MustPage("https://my.sa.ucsb.edu/gold/Login.aspx")
	page.MustEmulate(devices.LaptopWithHiDPIScreen)

	err := rod.Try(func() {
		page.MustElement("#pageContent_loginButtonCurrentStudent").MustClick()
		page.MustElement("#username").MustInput(credential.Username)
		time.Sleep(100 * time.Millisecond)
		page.MustElement("#password").MustInput(credential.Password)
		page.MustElement("#fm1 > input.btn.btn-block.btn-submit").MustClick()
		// Attempt to login to UCSB SSO
		page.Race().Element("#duo_iframe").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln("Waiting for Duo MFA for " + credential.Username + "@ucsb.edu")
			validCredential = true
		}).Element("#fm1 > div").MustHandle(func(e *rod.Element) {
			utils.SugarLogger.Infoln(e.MustText())
		}).MustDo()

		if validCredential {
			// Wait for Duo MFA
			page.MustWaitRequestIdle()
			time.Sleep(1500 * time.Millisecond)
			utils.SugarLogger.Infoln("clicking duo")
			// fuck duo man stupid cringe way to click the send push button
			page.MustElement("body > header > nav").MustClick()
			page.KeyActions().Press(input.Tab).MustDo()
			page.KeyActions().Press(input.Enter).MustDo()
			utils.SugarLogger.Infoln("sent duo push")

			page.Timeout(45 * time.Second).Race().Element("#MainForm > header > div > div.navbar-header.navbar-fixed-top").MustHandle(func(e *rod.Element) {
				utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
				duoAuthenticated = true
			}).MustDo()
		} else {
			utils.SugarLogger.Errorln("Invalid credentials for " + credential.Username + "@ucsb.edu")
			status = 1
		}
	})
	utils.SugarLogger.Infoln("Valid Credentials: " + strconv.FormatBool(validCredential))
	utils.SugarLogger.Infoln("Duo Authenticated: " + strconv.FormatBool(duoAuthenticated))
	if errors.Is(err, context.DeadlineExceeded) {
		utils.SugarLogger.Errorln(err.Error())
		utils.SugarLogger.Errorln("Duo MFA failed for " + credential.Username + "@ucsb.edu")
		status = 2
	} else if err != nil {
		utils.SugarLogger.Errorln("Webdriver error occurred: " + err.Error())
		if retry < maxRetries {
			retry++
			page.MustClose()
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return LoginGOLD(credential, retry)
		}
	}
	if status != 0 {
		page.MustClose()
	}
	return status, page
}

func FetchCoursesForUserForQuarter(page *rod.Page, credential model.UserCredential, quarter string, retry int) []model.UserCourse {
	maxRetries := 25
	var courses []model.UserCourse
	defer page.MustClose()
	err := rod.Try(func() {
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
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchCoursesForUserForQuarter(page, credential, quarter, retry)
		}
	}
	return courses
}

func FetchFinalsForUserForQuarter(page *rod.Page, credential model.UserCredential, quarter string, retry int) []model.UserFinal {
	maxRetries := 25
	var finals []model.UserFinal
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)
	err := rod.Try(func() {
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
		var finalNames []string
		filterWords := []string{"Unknown Date", "Contact Professor", "Course Info", "Drop", "Modify", "Remove"}
		for _, courseElement := range finalNameElements {
			filtered := false
			for _, filterWord := range filterWords {
				if strings.Contains(courseElement.MustText(), filterWord) {
					utils.SugarLogger.Infoln("Filtered out " + filterWord)
					filtered = true
				}
			}
			if !filtered && courseElement.MustText() != "" {
				utils.SugarLogger.Infoln(courseElement.MustText())
				finalNames = append(finalNames, courseElement.MustText())
			}
		}
		utils.SugarLogger.Infoln("Found " + strconv.Itoa(len(finalNames)) + " finals")
		finalElements := page.MustElements("div.col-sm-7.col-xs-12")
		counter := 0

		for _, courseElement := range finalElements {
			filtered := false
			for _, filterWord := range filterWords {
				if strings.Contains(courseElement.MustText(), filterWord) {
					utils.SugarLogger.Infoln("Filtered out from final times: " + filterWord)
					filtered = true
					counter++
				}
			}
			if !filtered && courseElement.MustText() != "" {
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
				startDate, err := time.Parse("January 02, 2006 3:04 PM (MST)", startParseString+" ("+currentZone+")")
				if err != nil {
					utils.SugarLogger.Errorln(err.Error())
					break
				}
				startDate = HandleDaylightSavings(startDate)
				utils.SugarLogger.Infoln(startDate.String())

				// December 11, 2023 3:00 PM
				endParseString := monthday + ", " + year + " " + endTime
				endDate, err := time.Parse("January 02, 2006 3:04 PM (MST)", endParseString+" ("+currentZone+")")
				if err != nil {
					utils.SugarLogger.Errorln(err.Error())
					break
				}
				endDate = HandleDaylightSavings(endDate)
				utils.SugarLogger.Infoln(endDate.String())

				finals = append(finals, model.UserFinal{
					UserID:    credential.UserID,
					Title:     strings.ReplaceAll(strings.Split(finalNames[counter], " - ")[0], " ", ""),
					Name:      strings.Split(finalNames[counter], " - ")[1],
					StartTime: startDate,
					EndTime:   endDate,
					Quarter:   quarter,
				})
				counter++
			}
		}
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchFinalsForUserForQuarter(page, credential, quarter, retry)
		}
	}
	return finals
}

func FetchPasstimeForUserForQuarter(page *rod.Page, credential model.UserCredential, quarter string, retry int) model.UserPasstime {
	maxRetries := 25
	var passtime model.UserPasstime
	defer page.MustClose()
	page.MustEmulate(devices.LaptopWithHiDPIScreen)
	err := rod.Try(func() {
		utils.SugarLogger.Infoln("Logged in successfully as " + credential.Username + "@ucsb.edu")
		page.MustWaitIdle().MustNavigate("https://my.sa.ucsb.edu/gold/RegistrationInfo.aspx")
		page.MustWaitIdle()
		page.MustElement("#pageContent_quarterDropDown")
		page.Eval("$('#pageContent_quarterDropDown option[value=\"" + quarter + "\"]').attr(\"selected\", \"selected\").change();")
		page.MustWaitIdle()
		utils.SugarLogger.Infoln("Selected quarter " + quarter)

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
	})
	if err != nil {
		if retry < maxRetries {
			retry++
			utils.SugarLogger.Infoln("WebDriver error, retrying " + strconv.Itoa(retry) + " of " + strconv.Itoa(maxRetries))
			return FetchPasstimeForUserForQuarter(page, credential, quarter, retry)
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
