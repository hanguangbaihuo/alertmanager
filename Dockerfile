ARG ARCH="amd64"
ARG OS="linux"
FROM golang:alpine

ADD . /sparrow
WORKDIR /sparrow

ENV GOPROXY "https://goproxy.cn,direct"
ENV CGO_ENABLED=0
RUN go mod vendor
RUN go build --mod=vendor -o alertmanager /sparrow/cmd/alertmanager/main.go

FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest

COPY --from=0 /sparrow/alertmanager /bin/
COPY --from=0 /sparrow/examples/ha/alertmanager.yml  /etc/alertmanager/alertmanager.yml
ENV TZ Asia/Shanghai

RUN mkdir -p /alertmanager && \
    chown -R nobody:nobody etc/alertmanager /alertmanager

USER       nobody
EXPOSE     9093
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]
