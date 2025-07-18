# ビルド用ステージ
FROM golang:1.24 AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o repirecipe

# 実行用ステージ
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/repirecipe .
CMD ["./repirecipe"]