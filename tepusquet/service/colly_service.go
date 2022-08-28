package service

import (
	"github.com/gocolly/colly/v2"
	"log"
)

var collyCollector = colly.NewCollector()

func InitializeColly() {
	collyCollector.OnRequest(func(r *colly.Request) {
		log.Println("Visiting", r.URL.String())
	})
	collyCollector.OnResponse(func(r *colly.Response) {
		log.Println("response received", r.StatusCode)
	})
	collyCollector.OnError(func(r *colly.Response, err error) {
		log.Println("error:", r.StatusCode, err)
	})
}
