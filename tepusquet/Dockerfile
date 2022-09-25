FROM golang:1.17.7-alpine3.15 as builder

ENV GOOS=linux

RUN apk --no-cache add ca-certificates
RUN apk add --no-cache tzdata

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . ./

RUN go build -o /tepusquet

##
## Deploy
##
FROM alpine:3.15

RUN apk --no-cache add chromium

WORKDIR /

COPY --from=builder /tepusquet /tepusquet

ENTRYPOINT ["/tepusquet"]