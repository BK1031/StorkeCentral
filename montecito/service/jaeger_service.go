package service

import (
	"context"
	"log"
	"montecito/config"
	"strconv"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
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
	tp, err := tracerProvider("http://localhost:14268/api/traces")
	if err != nil {
		log.Fatal(err)
	}

	// Register our TracerProvider as the global so any imported
	// instrumentation in the future will default to using it.
	otel.SetTracerProvider(tp)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	//tr := tp.Tracer(config.Service.Name)

	JaegerTest(ctx)
}

func JaegerTest(ctx context.Context) {
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(ctx, "bar")
	span.SetAttributes(attribute.Key("test_key").String("some-value"))
	defer span.End()

	time.Sleep(136 * time.Millisecond)
	println("JaegerTest")
}
