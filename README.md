# prometheus-snmp-exporter-synology-ds1621

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/2.1.0/wip.svg)](https://www.repostatus.org/#wip)

Prometheus snmp-exporter Docker image with Synology DS-1621+ config baked in.

**Docker Image:** https://hub.docker.com/r/jantman/prometheus-snmp-exporter-synology-ds1621

**Source Code:** https://github.com/jantman/prometheus-snmp-exporter-synology-ds1621

This repository generates a Docker image based on https://github.com/prometheus/snmp_exporter ( https://hub.docker.com/r/prom/snmp-exporter ), but with a baked-in `snmp.yml` suitable for Synology NASes running DSM 7 (tested against a DS-1621+ running DSM 7.1.1).

I've used this quite successfully with this Grafana dashboard: https://grafana.com/grafana/dashboards/14284-synology-nas-details/

To run this on the Synology itself via the Docker package, the container [must](https://community.synology.com/enu/forum/1/post/146351) be running with "host" networking. Port 9116 should be exposed.

You can then use a `prometheus.yml` entry like the following, where `MYNAS` is the hostname of your NAS:

```yaml
- job_name: 'synology_snmp'
  scrape_interval: 30s
  metrics_path: /snmp
  params:
    module: [ synology ]
  static_configs:
    - targets:
        - MYNAS
  relabel_configs:
    - source_labels: [ __address__ ]
      target_label: __param_target
    - source_labels: [ __param_target ]
      target_label: instance
    - target_label: __address__
      replacement: 'MYNAS:9116'
```

##  Release Process

Tag the repo. [GitHub Actions](https://github.com/jantman/prometheus-snmp-exporter-synology-ds1621/actions) will run a Docker build, push to Docker Hub, and create a release on the repo.
