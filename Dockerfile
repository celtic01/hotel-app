FROM golang:latest AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./app ./cmd/web

FROM alpine:latest  

WORKDIR /root/

COPY --from=builder /app/app .
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static  ./static

EXPOSE 8080

ENTRYPOINT [ "./app" ]

