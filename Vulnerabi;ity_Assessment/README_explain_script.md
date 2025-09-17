# README — Vulnerability Scan Script

This README explains the provided Bash script that scans subdomains, runs port and SSL checks, performs Nmap vulnerability scripts, parses results, and produces a top-10 summary of critical/high vulnerabilities.

---

## File
`scan_subdomains.sh` (example name)

## What the script does (high-level)
1. Creates an `output/` folder to store scan results.
2. Reads `subdomain.txt` line-by-line (each line should be a subdomain or host).
3. For each subdomain:
   - Checks if the host responds on HTTP (port 80) using `curl`.
   - If active:
     - Runs a full port scan with `nmap`.
     - Runs `sslscan` to collect SSL/TLS information.
     - Runs `nmap --script vuln` to run vulnerability NSE scripts.
     - Parses the Nmap vulnerability output into a temporary file.
4. After scanning all hosts, sorts and extracts the top 10 vulnerabilities by severity into `output/critical_vulns.txt`.
5. Prints a table of the top vulnerabilities and a short per-subdomain summary.

---

## Prerequisites
Make sure the following tools are installed and available in `PATH`:

- `bash`
- `nmap` (including NSE scripts)
- `curl`
- `sslscan`
- `awk`
- `grep`
- `sort`
- `column`

On Debian/Ubuntu:
```bash
sudo apt update
sudo apt install nmap curl sslscan gawk grep coreutils bsdmainutils
```

> Note: `sslscan` may be in different packages or repositories depending on distro.

---

## Usage
1. Put one target per line in `subdomain.txt`, for example:
```
example.com
sub.example.com
192.168.1.100
```

2. Make the script executable and run:
```bash
chmod +x scan_subdomains.sh
./scan_subdomains.sh
```

3. Results are written under the `output/` directory:
- `output/<subdomain>_ports.txt` — raw Nmap port scan
- `output/<subdomain>_ssl.txt` — sslscan output
- `output/<subdomain>_vuln.txt` — Nmap vuln script output
- `output/critical_vulns.txt` — consolidated top-10 table (subdomain, vuln, severity, CVE)

---

## Code walkthrough (important blocks)

### 1) Setup and header
```bash
mkdir -p output
summary_file="output/critical_vulns.txt"
echo -e "Subdomain	Vuln Name	Severity	CVE" > $summary_file
```
Creates the output directory and initializes the CSV-like summary file with tab separators.

---

### 2) Color variables
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
```
Terminal color codes for nicer console output.

---

### 3) `severity_to_num()` function
```bash
severity_to_num() {
    case $1 in
        CRITICAL) echo 1 ;;
        HIGH) echo 2 ;;
        MEDIUM) echo 3 ;;
        LOW) echo 4 ;;
        *) echo 5 ;;
    esac
}
```
Converts textual severity to numeric rank so you can sort (1 = most severe).  
⚠ Note: In the provided script this function is declared but not used — the sorting later uses an inline `awk` mapping instead.

---

### 4) Main loop — checking each subdomain
```bash
while read subdomain; do
    if curl -s --connect-timeout 5 http://$subdomain >/dev/null; then
        # active actions...
    else
        # not active
    fi
done < subdomain.txt
```
- Uses `curl` to test HTTP responsiveness.  
- If the site is active, it continues with scans. If not, it skips.

**Suggestion:** Consider using both `http://` and `https://` checks or probing ports directly with `nmap -Pn -p80,443` so HTTPS-only hosts are detected.

---

### 5) Nmap full-port scan
```bash
nmap -Pn -p- $subdomain -oN "output/${subdomain}_ports.txt"
grep "^[0-9]" "output/${subdomain}_ports.txt"
```
- `-Pn` disables host discovery (assumes host is up).
- `-p-` scans all ports.
- Output saved to a host-specific file and open ports are displayed by grepping lines starting with digits.

---

### 6) SSL and vulnerability scans
```bash
sslscan $subdomain > "output/${subdomain}_ssl.txt"
nmap -Pn --script vuln $subdomain -oN "output/${subdomain}_vuln.txt"
```
- `sslscan` finds SSL/TLS config details.
- `nmap --script vuln` runs vulnerability NSE scripts and outputs findings.

---

### 7) Parsing vulnerability output
```bash
awk '
/VULNERABLE/ {vulnname=$0}
/Severity/ {sev=$2}
/CVE/ {cve=$0; print vulnname"	"sev"	"cve}
' "output/${subdomain}_vuln.txt" >> temp_vuln.txt
```
This `awk` tries to capture lines that mention vulnerability names, severity, and CVE references and writes tab-separated records to `temp_vuln.txt`.

**Caveats:**
- Nmap output is not strictly structured; this parsing may miss or combine fields incorrectly.
- Depending on NSE script formats, `Severity` or `CVE` lines may not exist or may appear in different formats.
- Consider using more robust parsing or using `grep -P`/`sed` or writing a small parser in Python to handle multiline entries.

---

### 8) Sorting and extracting top 10
```bash
awk -F'\t' '{
    if ($2=="CRITICAL") s=1
    else if ($2=="HIGH") s=2
    else if ($2=="MEDIUM") s=3
    else if ($2=="LOW") s=4
    else s=5
    print s"\t"$0
}' temp_vuln.txt | sort -n | cut -f2- | head -n 10 >> $summary_file
```
- Prepends numeric severity, sorts numerically (so CRITICAL come first), strips the numeric field, and keeps the top 10 records.

---

### 9) Cleanup & reporting
```bash
rm temp_vuln.txt
column -t -s $'\t' $summary_file
awk -F'\t' '{count[$1]++} END {for (sub in count) print sub, ": ", count[sub], "critical vulns"}' $summary_file
```
- Deletes the temporary parsed file.
- Prints the summary file in a nicely aligned table.
- Shows counts per subdomain.

---

## Output example
```
=== Top 10 Critical Vulnerabilities ===
Subdomain              Vuln Name                               Severity  CVE
example.com            SSL certificate uses weak signature     CRITICAL  CVE-YYYY-XXXX
sub.example.com        HTTP TRACE enabled                      HIGH      CVE-YYYY-YYYY

=== Summary per Subdomain ===
example.com :  2 critical vulns
sub.example.com :  1 critical vulns

All done! Detailed output is in ./output/
```

---

## Improvements & Recommendations
- **HTTPS-only hosts:** probe both `http` and `https` (or use `nmap` host discovery) to avoid skipping hosts that refuse HTTP.
- **Parallelization:** use `xargs -P` or `GNU parallel` to scan multiple hosts concurrently (be mindful of rate limits and target permission).
- **Robust parsing:** Nmap output varies by NSE script. Use `--script` targeting specific scripts that output consistent fields, or parse the XML output (`-oX`) and process it with tools or Python.
- **Rate limiting & legality:** Always ensure you have permission to scan targets. Scanning the internet without permission can be illegal.
- **Use XML for structured parsing:** `nmap -oX` produces machine-readable output; parsing XML is more reliable than grepping text output.
- **Logging & timestamps:** include timestamps in filenames for historical results.
- **Use `set -euo pipefail` and safer temporary files:** make the script more robust and fail-safe.
- **Sanitize filenames:** subdomains containing `/` or special characters can break file paths. Consider replacing chars when creating filenames.

---

## Security & Legal Notice
**Only scan systems you own or have explicit permission to test.** Unauthorized scanning can be illegal and may cause service disruption.

---

## License
You can reuse and adapt this README however you like. If you want, I can add a LICENSE file (MIT, Apache-2.0, etc.) for the script.

