package model

import "time"

type Response struct {
	Status    string      `json:"status"`
	Ping      string      `json:"ping"`
	Timestamp time.Time   `json:"timestamp"`
	Service   string      `json:"service"`
	Message   string      `json:"message,omitempty"`
	Data      interface{} `json:"data,omitempty"`
}
