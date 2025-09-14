#!bin/bash
set -euo pipefail

echo "===================INFORMATION SYSTEM========================"
#System information
host_name=$(hostname 2>/dev/null || echo "unknown host")
user_id=$(id -u 2>/dev/null || echo "0")
user_name=$(whoami 2>/dev/null || echo "$USER")

#Get Current IP
if command -v hostname >/dev/null 2>&1 && hostname -I >/dev/null 2>&1; then
  current_ip=$(hostname -I | awk '{print $1}')
else
  current_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7; exit}' || echo "0.0.0.0")
fi

#show information
echo "============System Information=========="
echo "Hostname: $host_name"
echo "User ID: $user_id"
echo "Username: $user_name"
echo "Current IP: $current_ip"

#set up environment

pentest_target="hertz.com" #fill with your target"
pentest_type="network"
output_dir="./results"
log_level="info"

mkdir -p "$output_dir"

#tools configuration
nmap_opt="-sS -sV -O --version-intensity 5" #can custom for another options
sqlmap_opt="--batch --risk=3 --level=5"
#can add for your another tools

#utility function
log() {
  local level="$1"; shift
  local msg="$*"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg"
}

echo "============Start Recon======================"
#main execution
log "info" "starting reconnaissance on $pentest_target"

if [[ "$pentest_type" == "network" && -n "$pentest_target" ]]; then
  log "INFO" "Running Nmap scan.."
  nmap $nmap_opt -oN "$output_dir/nmap_scan.txt" "$pentest_target"
  sqlmap -u "$pentest_target" $sqlmap_opt --output-dir="$output_dir/sqlmap" || log "error" "sqlmap failed for $pentest_target"
fi




