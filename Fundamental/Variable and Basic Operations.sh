#!/bin/bash

#variable declaration
target_ip="192.168.1.100" #change the target for what you want
port=80
scan_type="TCP"

#String Concatenation
full_target="${target_ip}:${port}"
log_message="Scanning ${full_target}:Using ${scan_type}"

#numeric Operation
total_port=$((port + 21 + 443 + 8080))
echo "Total Ports to Scan : $total_port"

#arrays for multiple target
targets= "192.168.1.100" "192.168.1.182" "192.168.1.183"
ports= ( 21 22 23 25 53 80 110 443 993 995 )

echo "Targets : ${targets[@]}"
echo "Ports : ${ports[@]}"
echo "Total Targets : ${#targets[@]}"



