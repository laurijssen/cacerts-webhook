FROM golang:1.24 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o cacerts-webhook

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/cacerts-webhook .

EXPOSE 8080

CMD ["/app/cacerts-webhook" ]
