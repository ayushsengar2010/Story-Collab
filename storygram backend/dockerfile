# Stage 1: Build the Go app
FROM golang:latest AS builder

WORKDIR /app

# Copy go.mod and go.sum and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the app source code
COPY . .

# Build the Go binary
RUN go build -o myapp

# Stage 2: Run the Go app using a minimal image
FROM alpine:latest

WORKDIR /root/

# Copy the built binary
COPY --from=builder /app/myapp .

# Run the binary
CMD ["./myapp"]
