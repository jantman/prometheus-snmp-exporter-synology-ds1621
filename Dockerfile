FROM prom/snmp-exporter:v0.31.0
COPY snmp.yml /etc/snmp_exporter/snmp.yml
