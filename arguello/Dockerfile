FROM golang:1.17.7-alpine3.15 as builder

ENV GOOS=linux

RUN apk --no-cache add ca-certificates
RUN apk add --no-cache tzdata

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . ./

RUN go build -o /arguello

##
## Deploy
##
FROM alpine:3.15

WORKDIR /

COPY --from=builder /arguello /arguello

ENTRYPOINT ["/arguello"]