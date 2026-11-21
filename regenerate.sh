#!/usr/bin/env bash
#
# Regenerate snmp.yml from generator.yml with the snmp_exporter generator at the
# same version as the Dockerfile's base image.
#
# MIBs are downloaded by the upstream generator Makefile (at that same tag), so
# they come from the same sources, with the same patches, that upstream uses
# for its own bundled snmp.yml:
#   - net-snmp 5.9 MIBs (SNMPv2, IF-MIB, HOST-RESOURCES-MIB, UCD-SNMP-MIB, ...)
#   - IANAifType-MIB from iana.org
#   - Synology's official Synology_MIB_File.zip, plus upstream's mib-patches
#
# One deviation from upstream: UCD-SNMP-MIB comes from net-snmp master (pinned
# below) instead of the v5.9 branch, because only master defines memSysAvail
# (memory.27), which DSM implements and the 0.1.0 image exported.
#
# Requires: docker, git, make, curl, unzip, patch.
#
# Copyright 2026 Jason Antman <jason@jasonantman.com>
#
set -euo pipefail

cd "$(dirname "$0")"
VERSION="$(sed -n 's|^FROM prom/snmp-exporter:\(v[0-9.]*\)$|\1|p' Dockerfile)"
if [[ -z "$VERSION" ]]; then
  echo "ERROR: could not find prom/snmp-exporter version in Dockerfile" >&2
  exit 1
fi
echo ">> Using snmp_exporter ${VERSION}"

# net-snmp master commit for UCD-SNMP-MIB; see above.
UCD_MIB_COMMIT=f3c859515e916cdee899255df372a9045b63a82a

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

git clone -q --depth 1 --branch "$VERSION" \
  https://github.com/prometheus/snmp_exporter.git "$WORKDIR/snmp_exporter"
GENDIR="$WORKDIR/snmp_exporter/generator"
make -C "$GENDIR" mibs/.net-snmp mibs/IANA-IFTYPE-MIB.txt mibs/.synology
curl -L -sS --fail -o "$GENDIR/mibs/UCD-SNMP-MIB" \
  "https://raw.githubusercontent.com/net-snmp/net-snmp/${UCD_MIB_COMMIT}/mibs/UCD-SNMP-MIB.txt"

cp generator.yml "$GENDIR/generator.yml"
docker run --rm --user "$(id -u):$(id -g)" -v "$GENDIR:/opt" \
  "prom/snmp-generator:${VERSION}" \
  --fail-on-parse-errors generate --output-path=/opt/snmp.yml
cp "$GENDIR/snmp.yml" snmp.yml
echo ">> Wrote snmp.yml"
