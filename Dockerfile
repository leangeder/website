###
FROM golang as builder
COPY . /go/src/leangeder/website/
WORKDIR /go/src/leangeder/website/
RUN go get -d -v
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main ./src/.
####
FROM golang as dev
RUN go get github.com/cespare/reflex
CMD ["reflex", "-s", "-g", ".reflex.conf", "--", "reflex", "-c", ".reflex.conf"]
####
FROM scratch
WORKDIR /app
COPY --from=builder /go/src/leangeder/website/main /app
CMD ["./main"]
