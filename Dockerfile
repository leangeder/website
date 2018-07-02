FROM golang as builder
COPY . /go/src/leangeder/website/
WORKDIR /go/src/leangeder/website/
RUN go get -d -v
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main ./src/.
####
FROM scratch
WORKDIR /app
COPY --from=builder /go/src/leangeder/website/main /app
CMD ["./main"]
