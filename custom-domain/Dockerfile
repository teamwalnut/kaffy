FROM golang:1.16-buster AS build

RUN mkdir /build 

ADD . /build/

WORKDIR /build 

RUN go test ./...

RUN go build -o custom-domains .

FROM gcr.io/distroless/base-debian10 as app

WORKDIR /

COPY --from=build /build/custom-domains /custom-domains 

USER nonroot:nonroot

ENTRYPOINT ["/custom-domains"] 