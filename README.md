# Docker image for go-carbon + carbonapi + statsd

## Quick Start

```sh
docker run -d \
 --name go-graphite \
 --restart=always \
 -p 2003:2003/udp \
 -p 2003-2004:2003-2004 \
 -p 8081:8081 \
 -p 8125:8125/udp \
 nordling/go-graphite
```

### Includes the following components

* [Go-carbon](https://github.com/lomik/go-carbon) - Golang implementation of Graphite/Carbon server
* [Carbonapi](https://github.com/go-graphite/carbonapi) - Golang implementation of Graphite-web
* [Statsd](https://github.com/statsd/statsd) - Statsd network metrics collector

### Mapped Ports

Host | Container | Service
---- | --------- | -------------------------------------------------------------------------------------------------------------------
2003 |      2003 | [carbon receiver - plaintext](http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-plaintext-protocol)
2004 |      2004 | [carbon receiver - pickle](http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-pickle-protocol)
8081 |      8081 | [carbonapi](https://github.com/go-graphite/carbonapi)

### Mounted Volumes

Host              | Container                  | Notes
----------------- | -------------------------- | -------------------------------
DOCKER ASSIGNED   | /etc/go-carbon             | go-carbon configs (see )
DOCKER ASSIGNED   | /var/lib/graphite          | graphite file storage
DOCKER ASSIGNED   | /etc/carbonapi             | Carbonapi config
DOCKER ASSIGNED   | /etc/logrotate.d           | logrotate config
DOCKER ASSIGNED   | /var/log                   | log files

### External Grafana connect

For external Grafana datasource must use CarbonAPI port - 8081/tcp

For example - [grafana-carbonapi](https://github.com/go-graphite/docker-go-graphite/blob/master/conf/etc/grafana/provisioning/datasources/carbonapi.yaml)

### Statsd

Thanks for:
 
* [Graphite Project](https://github.com/graphite-project/docker-graphite-statsd)
* [Go-Graphite Project](https://github.com/go-graphite)
* [Statsd Project](https://github.com/statsd/statsd)
