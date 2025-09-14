#!/usr/bin/env bas
#variable declaration
scan_type="TCP"

#Arrays for multiple targets
targets=("192.168.1.100" "192.168.1.102" "192.168.1.103") #this targets are unreal, you can change for yours targets
ports=(21 22 23 24 25 53 80 443 993 993)

#Display summary
echo "=========Summary===================="
echo "Scan Summary"
echo "Targets           : ${targets[@]}"
echo "Ports             : ${ports[@]}"
echo "Total Targets     : ${#targets[@]}"
echo "Total Ports       : ${#ports[@]}"
echo "Scan Type         : $scan_type"
echo "===================================="

#scan loop using netcat for example
for t in "${targets[@]}"; do
  echo "==Scanning $t=="
  for p in "${ports[@]}"; do
    if nc -z -w1 "$t" "$p" >/dev/null 2>&1; then
      printf "%s:%-5s %s\n" "$t" "$p" "open"
    else
      printf "%s:%-5s %s\n" "$t" "$p" "closed"
    fi
  done
  echo ""





