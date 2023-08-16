package utils

import (
	"context"
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	oteltrace "go.opentelemetry.io/otel/trace"
	"jalama/config"
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
	//jaegerUrl := "http://localhost:" + utils.JaegerPort + "/api/traces" // Use this when not running in Docker
	jaegerUrl := "http://jaeger:" + config.JaegerPort + "/api/traces"
	tp, err := tracerProvider(jaegerUrl)
	if err != nil {
		SugarLogger.Errorln(err)
	}
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
}

func JaegerPropogator() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse the traceparent header to get the trace and span IDs
		if c.Request.Header.Get("traceparent") != "" {
			ctx := c.Request.Context()
			p := propagation.TraceContext{}
			sc := p.Extract(ctx, propagation.HeaderCarrier(c.Request.Header))

			// Now, you have the extractedSpanContext object
			extractedSpanContext := oteltrace.SpanContextFromContext(sc)

			// Set the extracted trace context in the request context
			ctx = oteltrace.ContextWithRemoteSpanContext(ctx, extractedSpanContext)
			c.Request = c.Request.WithContext(ctx)
		}

		c.Next()
	}
}

func BuildSpan(context context.Context, name string, attributes oteltrace.SpanStartEventOption) oteltrace.Span {
	tr := otel.Tracer(config.Service.Name)
	_, span := tr.Start(context, name, attributes)

	return span
}

func BuildTraceparent(span oteltrace.Span) string {
	sc := span.SpanContext()
	return "00-" + sc.TraceID().String() + "-" + sc.SpanID().String() + "-01"
}
