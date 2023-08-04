package service

import (
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"log"
	"montecito/config"
	"strconv"
)

func tracerProvider(url string) (*tracesdk.TracerProvider, error) {
	// Create the Jaeger exporter
	exp, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(url)))
	if err != nil {
		return nil, err
	}
	tp := tracesdk.NewTracerProvider(
		// Always be sure to batch in production.
		tracesdk.WithBatcher(exp),
		// Record information about this application in a Resource.
		tracesdk.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(config.Service.Name),
			semconv.ServiceVersion(config.Service.Version),
			semconv.ServiceInstanceID(strconv.Itoa(config.Service.ID)),
			attribute.String("environment", config.Env),
			attribute.Int64("ID", int64(config.Service.ID)),
		)),
	)
	return tp, nil
}

func InitializeJaeger() {
	//jaegerUrl := "http://localhost:" + config.JaegerPort + "/api/traces" // Use this when not running in Docker
	jaegerUrl := "http://jaeger:" + config.JaegerPort + "/api/traces"
	tp, err := tracerProvider(jaegerUrl)
	if err != nil {
		log.Fatal(err)
	}
	otel.SetTracerProvider(tp)
}
