package service

import (
	"gaviota/utils"
	colly "github.com/gocolly/colly/v2"
)

var collyCollector = colly.NewCollector()

func InitializeColly() {
	collyCollector.OnRequest(func(r *colly.Request) {
		utils.SugarLogger.Infoln("Visiting", r.URL.String())
	})
	collyCollector.OnResponse(func(r *colly.Response) {
		utils.SugarLogger.Infoln("response received", r.StatusCode)
	})
	collyCollector.OnError(func(r *colly.Response, err error) {
		utils.SugarLogger.Errorln("error:", r.StatusCode, err)
	})
}
