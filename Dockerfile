FROM prom/snmp-exporter:v0.21.0
COPY snmp.yml /etc/snmp_exporter/snmp.yml
