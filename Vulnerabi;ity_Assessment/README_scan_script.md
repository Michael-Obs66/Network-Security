# 🛡️ Subdomain Vulnerability Scanner

[![Bash Script](https://img.shields.io/badge/Script-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Nmap](https://img.shields.io/badge/Tool-Nmap-blue.svg)](https://nmap.org/)
[![SSLScan](https://img.shields.io/badge/Tool-SSLScan-orange.svg)](https://github.com/rbsec/sslscan)
[![Linux](https://img.shields.io/badge/Platform-Linux-green.svg)](https://www.linux.org/)

📘 **About This Script**
This Bash script automates **subdomain security scanning**. It checks subdomain availability, performs **port scanning**, **SSL/TLS inspection**, and **vulnerability scanning**, then creates a summary report of the **Top 10 critical vulnerabilities**.

---

## ⚡ Features
- ✅ Reads targets from `subdomain.txt`
- ✅ Detects if the subdomain is alive (HTTP check)
- ✅ Full port scan with `nmap`
- ✅ SSL/TLS scan with `sslscan`
- ✅ Vulnerability scan with `nmap --script vuln`
- ✅ Extracts severity & CVEs from results
- ✅ Generates a **Top-10 Critical Vulnerabilities** summary
- ✅ Colored terminal output for clarity

---

## 🛠 Requirements
Make sure the following tools are installed:
- **nmap**
- **curl**
- **sslscan**
- **awk**, **grep**, **sort**, **column**

Example installation (Debian/Ubuntu):
```bash
sudo apt update
sudo apt install nmap curl sslscan gawk grep coreutils bsdmainutils
```

---

## 🚀 Usage
1. Add your targets to `subdomain.txt` (one per line):
   ```
   example.com
   api.example.com
   192.168.1.100
   ```
2. Run the script:
   ```bash
   chmod +x scan_subdomains.sh
   ./scan_subdomains.sh
   ```
3. Results:
   - Raw outputs in `./output/`
   - Summary table in `output/critical_vulns.txt`

---

## 📂 Output Files
- `output/<subdomain>_ports.txt` → Nmap port scan results
- `output/<subdomain>_ssl.txt` → SSLScan results
- `output/<subdomain>_vuln.txt` → Nmap vulnerability scan results
- `output/critical_vulns.txt` → Final summary (Top-10 critical vulns)

---

## 🔎 Script Walkthrough
### 1. Check if subdomain is alive
```bash
if curl -s --connect-timeout 5 http://$subdomain >/dev/null; then
  echo "$subdomain is ACTIVE"
else
  echo "$subdomain is NO-ACTIVE"
fi
```

### 2. Run scans (for active hosts)
- **Port scan**: `nmap -Pn -p- <subdomain>`
- **SSL scan**: `sslscan <subdomain>`
- **Vuln scan**: `nmap -Pn --script vuln <subdomain>`

### 3. Parse vulnerabilities
Extracts `VULNERABLE`, `Severity`, and `CVE` lines from Nmap output into `temp_vuln.txt`.

### 4. Sort by severity
Critical → High → Medium → Low.
Top 10 results are saved in `critical_vulns.txt`.

### 5. Display results
- Pretty table using `column -t`
- Subdomain summary using `awk`

---

## 📊 Example Output
```
=== Top 10 Critical Vulnerabilities ===
Subdomain      Vuln Name                               Severity   CVE
example.com    SSL certificate uses weak signature     CRITICAL   CVE-2020-XXXX
api.example.com Outdated OpenSSL                       HIGH       CVE-2018-YYYY
```

---

## ⚠️ Limitations
- Only checks HTTP — HTTPS-only hosts may be skipped.
- Parsing relies on raw Nmap text (not always consistent).
- Temporary files (`temp_vuln.txt`) may be unsafe if run in parallel.

---

## 🚧 Recommended Improvements
- 🔹 Add HTTPS detection (`https://`) in alive check
- 🔹 Use `nmap -oX` and parse XML for reliability
- 🔹 Sanitize subdomain names for filenames
- 🔹 Add timestamps to avoid overwriting results
- 🔹 Parallelize scans for speed (GNU parallel)

---

## 📜 Disclaimer
⚠️ **Run only on systems you own or are explicitly authorized to test.**
Unauthorized scanning may be illegal.

---
