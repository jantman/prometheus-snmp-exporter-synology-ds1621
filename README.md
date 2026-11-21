# prometheus-snmp-exporter-synology-ds1621

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

Prometheus snmp-exporter Docker image with Synology DS-1621+ config baked in.

**Docker Image:** https://hub.docker.com/r/jantman/prometheus-snmp-exporter-synology-ds1621

**Source Code:** https://github.com/jantman/prometheus-snmp-exporter-synology-ds1621

This repository generates a Docker image based on https://github.com/prometheus/snmp_exporter ( https://hub.docker.com/r/prom/snmp-exporter ), but with a baked-in `snmp.yml` suitable for Synology NASes running DSM 7 (tested against a DS-1621+ running DSM 7.4). The `snmp.yml` contains one module, `synology`, and one auth, `public_v2` (SNMP v2c, community `public`), which is the exporter's default auth, so a scrape only needs the `module` param.

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

If your NAS uses a community other than `public`, change it in `generator.yml` and regenerate `snmp.yml`, or mount your own `snmp.yml` over `/etc/snmp_exporter/snmp.yml`.

## Regenerating snmp.yml

`snmp.yml` is generated from `generator.yml`; don't edit it by hand. Run `./regenerate.sh` (needs docker, git, make, curl, unzip and patch). It uses the `prom/snmp-generator` image at the same version as the `FROM` line in the `Dockerfile`, and downloads the MIBs with the upstream generator Makefile at that tag: the net-snmp 5.9 MIBs, the IANA ifType MIB, and Synology's official [Synology_MIB_File.zip](https://global.download.synology.com/download/Document/Software/DeveloperGuide/Firmware/DSM/All/enu/Synology_MIB_File.zip) with upstream's MIB patches applied. The one exception is `UCD-SNMP-MIB`, taken from a pinned net-snmp master commit because only that version defines `memSysAvail`. To move to a new snmp_exporter release, change the `FROM` line, run `./regenerate.sh`, and compare a scrape before and after.

## Changelog

### 0.2.0 (2026-11-21)

* Base image `prom/snmp-exporter` v0.21.0 to v0.31.0; `snmp.yml` regenerated with the v0.31.0 generator, using the new `auths`/`modules` format (since v0.23.0).
* Added `regenerate.sh` and documented where the MIBs come from.
* Metric changes, compared by scraping a DS-1621+ on DSM 7.4 with 0.1.0 and with this version. No metric was removed or renamed, and no metric changed type.
  * New metrics: `cpuUtilization`, `memUtilization` and `thermalStatus` (from upstream's SYNOLOGY-SYSTEM-MIB patch) and `diskSMARTAttrRaw64` (the 64-bit raw SMART value, from upstream's SYNOLOGY-SMART-MIB patch).
  * `version` and `serialNumber` label values are now plain strings (`DSM 7.4-90080`) instead of hex (`0x44534D...`).
  * `ifType_info` `ifType` label values follow the current IANA ifType MIB: `ethernet-csmacd` is now `ethernetCsmacd`, and type 131, previously shown as `131`, is now `tunnel`.
  * `snmp_scrape_*` metrics now carry a `module` label (since v0.24.0).
  * The v0.31.0 change that maps enum lookup columns to strings does not affect this module: none of its lookups is an enum.
* Release workflow: updated actions, and `gh release create` replaces the archived `actions/create-release`.

### 0.1.0 (2023-02-26)

* Initial release, based on `prom/snmp-exporter` v0.21.0.

## Release Process

Tag the repo. [GitHub Actions](https://github.com/jantman/prometheus-snmp-exporter-synology-ds1621/actions) will run a Docker build, push to Docker Hub, and create a release on the repo.
