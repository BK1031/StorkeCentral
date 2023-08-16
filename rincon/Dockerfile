FROM golang:1.20-alpine3.17 as builder

ENV GOOS=linux

RUN apk --no-cache add ca-certificates
RUN apk add --no-cache tzdata

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . ./

RUN go build -o /rincon

##
## Deploy
##
FROM alpine:3.17

WORKDIR /

COPY --from=builder /rincon /rincon

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
ENV TZ=America/Los_Angeles

ENTRYPOINT ["/rincon"]