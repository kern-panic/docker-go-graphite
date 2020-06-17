# ---------------------- BUILD IMAGE ---------------------------------------
FROM golang:1-alpine as builder

ENV GOCARBON_VERSION='0.14.0'
ENV CARBONAPI_VERSION='0.13.0'
ENV GOPATH='/opt/go'
ENV STATSD_VERSION='0.8.6'

RUN apk update  --no-cache \
  && apk upgrade --no-cache \
  && apk add g++ git make musl-dev cairo-dev

# Install go-carbon
WORKDIR ${GOPATH}
RUN export PATH="${PATH}:${GOPATH}/bin" \
  && mkdir -p /var/log/go-carbon \
  && git clone https://github.com/lomik/go-carbon.git

WORKDIR ${GOPATH}/go-carbon
RUN export PATH="${PATH}:${GOPATH}/bin" \
  && git checkout "tags/v${GOCARBON_VERSION}" 2> /dev/null \
  && version=$(git describe --tags --always | sed 's/^v//') \
  && echo "build version: ${version}" \
  && make \
  && mv go-carbon /tmp/go-carbon

# Install carbonapi
WORKDIR ${GOPATH}
RUN export PATH="${PATH}:${GOPATH}/bin" \
  && mkdir -p /var/log/carbonapi \
  && git clone https://github.com/go-graphite/carbonapi.git

WORKDIR ${GOPATH}/carbonapi
RUN export PATH="${PATH}:${GOPATH}/bin" \
  && git checkout "tags/${CARBONAPI_VERSION}" 2> /dev/null \
  && version=${CARBONAPI_VERSION} \
  && echo "build version: ${version}" \
  && make \
  && mv carbonapi /tmp/carbonapi

# Fetch statsd
WORKDIR /opt
RUN git clone https://github.com/statsd/statsd.git \
 && cd /opt/statsd \
 && git checkout tags/v"${STATSD_VERSION}" 2> /dev/null \
 && rm -rf .git \
 && mv /opt/statsd /tmp/statsd

# ------------------------------ RUN IMAGE --------------------------------------
FROM node:lts-alpine3.12

ENV TZ='Etc/UTC'
ENV STATSD_INTERFACE='udp'
ENV CXXFLAGS='-Wno-cast-function-type'

RUN apk update --no-cache \
  && apk upgrade --no-cache \
  && apk add --no-cache --virtual .build-deps \
    cairo \
    shadow \
    tzdata \
    runit \
    dcron \
    logrotate \
    libc6-compat \
    ca-certificates \
    su-exec \
    bash \
    alpine-sdk \
    python3 \
  && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
  && echo "${TZ}" > /etc/timezone \
  && /usr/sbin/useradd \
    --system \
    -U \
    -s /bin/false \
    -c "User for Graphite daemon" \
    carbon \
  && mkdir /var/log/go-carbon \
  && chown -R carbon:carbon /var/log/go-carbon \
  && rm -rf \
    /tmp/* \
    /var/cache/apk/*

# Install go-carbon
COPY --from=builder /tmp/go-carbon /usr/bin/go-carbon

# Install carbonapi
COPY --from=builder /tmp/carbonapi /usr/bin/carbonapi

# install statsd
COPY --from=builder /tmp/statsd /opt/statsd

RUN cd /opt/statsd \
  && npm install \
  && npm cache clean --force

# Copy configs
COPY conf/ /

VOLUME ["/etc/go-carbon", "/etc/carbonapi", "/var/lib/graphite", "/etc/logrotate.d", "/var/log"]

ENV HOME /root

EXPOSE 2003 2003/udp 2004 8080 8081 8125 8125/udp 8126

CMD ["/entrypoint.sh"]
