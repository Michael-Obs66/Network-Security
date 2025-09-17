# README — Script: `scan_subdomains.sh`
**Bahasa:** Indonesia

README ini menjelaskan file bash `scan_subdomains.sh` secara fokus untuk MEMAHAMI apa yang dilakukan setiap bagian kode, bagaimana menjalankannya, dan rekomendasi perbaikan. Cocok untuk dokumentasi internal repo atau catatan pribadi saat belajar.

---

## Ringkasan singkat
Script ini membaca daftar `subdomain.txt` (satu target per baris), mengecek apakah host aktif (HTTP), lalu untuk host yang aktif menjalankan:
- scan port penuh dengan `nmap`,
- pengecekan SSL/TLS dengan `sslscan`,
- menjalankan `nmap --script vuln` (NSE vuln scripts),
- mem-parse hasil vuln ke file sementara,
- setelah semua target diproses, mengambil **Top 10** kerentanan berdasarkan severity dan menulis ringkasan ke `output/critical_vulns.txt`.

---

## File yang dihasilkan (folder `output/`)
- `<subdomain>_ports.txt` — output Nmap port scan (raw)
- `<subdomain>_ssl.txt` — output sslscan (raw)
- `<subdomain>_vuln.txt` — output Nmap vuln scripts (raw)
- `critical_vulns.txt` — ringkasan Top-10 (tab-separated)

---

## Prasyarat
Pastikan tool ini tersedia dan dapat dijalankan:
- bash
- nmap (lengkap dengan NSE scripts)
- curl
- sslscan
- awk, grep, sort, column
- (opsional) xmlstarlet atau Python jika ingin parsing XML

Contoh install (Debian/Ubuntu):
```bash
sudo apt update
sudo apt install nmap curl sslscan gawk grep coreutils bsdmainutils
```

---

## Cara menjalankan
1. Siapkan `subdomain.txt` (satu host/subdomain per baris):
```
example.com
sub.example.com
192.168.1.100
```
2. Pastikan script executable lalu jalankan:
```bash
chmod +x scan_subdomains.sh
./scan_subdomains.sh
```
3. Lihat hasil di folder `output/` dan ringkasan `output/critical_vulns.txt`.

> **PENTING:** Hanya jalankan terhadap target yang Anda miliki atau punya izin eksplisit untuk dites.

---

## Penjelasan kode — blok per blok (fokus memahami)

### 1. Shebang & direktori output
```bash
#!/bin/bash
mkdir -p output
summary_file="output/critical_vulns.txt"
echo -e "Subdomain	Vuln Name	Severity	CVE" > $summary_file
```
- `mkdir -p output`: pastikan folder output ada.
- `summary_file` diisi header kolom (tab-separated).

---

### 2. Warna terminal (kosmetik)
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
```
Mempermudah pembacaan output di terminal (merah, hijau, kuning).

---

### 3. Fungsi `severity_to_num()`
```bash
severity_to_num() { case $1 in ... ) ...; }
```
Mengubah label severity menjadi angka (CRITICAL => 1, HIGH => 2, ...). **Catatan:** fungsi ini dideklarasikan namun **tidak dipakai** di sorting akhir (sorting menggunakan `awk` terpisah).

---

### 4. Loop membaca `subdomain.txt` dan cek aktif
```bash
while read subdomain; do
  if curl -s --connect-timeout 5 http://$subdomain >/dev/null; then
    # host aktif -> jalankan scan
  else
    # host tidak aktif -> skip
  fi
done < subdomain.txt
```
- `curl` ke `http://<subdomain>` digunakan sebagai indikator "aktif".
- **Keterbatasan**: host HTTPS-only akan terlewat (anggap tidak aktif).

---

### 5. Scan untuk host aktif
```bash
nmap -Pn -p- $subdomain -oN "output/${subdomain}_ports.txt"
sslscan $subdomain > "output/${subdomain}_ssl.txt"
nmap -Pn --script vuln $subdomain -oN "output/${subdomain}_vuln.txt"
```
- `-Pn` memaksa Nmap untuk asumsi host up (tanpa discovery).
- `-p-` memeriksa semua port.
- Hasil tiap scan disimpan ke file terpisah.

---

### 6. Parsing hasil Nmap vuln (heuristik)
```bash
awk '
/VULNERABLE/ {vulnname=$0}
/Severity/ {sev=$2}
/CVE/ {cve=$0; print vulnname"	"sev"	"cve}
' "output/${subdomain}_vuln.txt" >> temp_vuln.txt
```
- Mencari baris yang mengandung `VULNERABLE`, `Severity`, dan `CVE`, lalu membuat baris tab-separated ke `temp_vuln.txt`.
- **Risiko**: output Nmap NSE tidak selalu konsisten → parsing teks ini rentan salah tangkap/miss. Untuk produksi, parsing XML (`-oX`) lebih direkomendasikan.

---

### 7. Sorting & mengambil Top 10
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
- Menambahkan skor numerik berdasarkan kolom severity (diasumsikan di kolom ke-2).
- Mengurutkan numerik sehingga CRITICAL muncul di atas, lalu ambil 10 pertama.

---

### 8. Tampilkan hasil & ringkasan per subdomain
```bash
column -t -s $'\t' $summary_file
awk -F'\t' '{count[$1]++} END {for (sub in count) print sub, ": ", count[sub], "critical vulns"}' $summary_file
```
- `column -t` membuat tampilan tabel rapi di terminal.
- `awk` menghitung jumlah entry per subdomain dari file ringkasan.

---

## Kelemahan utama & rekomendasi perbaikan (prioritas)
1. **Detect HTTPS-only hosts**: periksa juga `https://` atau gunakan `nmap` untuk discovery.
2. **Parsing yang lebih andal**: gunakan `nmap -oX` lalu parse XML (xmlstarlet / Python). Lebih aman daripada `awk` heuristik.
3. **Sanitize nama file**: ganti karakter berbahaya sebelum membuat nama file (contoh: `safe=$(echo "$subdomain" | tr '/: ' '_' )`).
4. **Gunakan file sementara aman**: pakai `mktemp` untuk menghindari race conditions.
5. **Tambahkan set -euo pipefail**: semakin robust script (fail fast on errors).
6. **Tambahkan timestamp pada nama file** agar hasil historis tidak tertimpa.
7. **Paralelisasi (opsional)**: `xargs -P`/`parallel` untuk daftar besar; hati-hati soal izin & load.
8. **Logging**: simpan log run (stdout/stderr) dengan timestamp untuk audit.

---

## Contoh perubahan kecil (snippet rekomendasi)
```bash
set -euo pipefail
mkdir -p output
summary_file="output/critical_vulns_$(date +%Y%m%d_%H%M%S).txt"
temp=$(mktemp)
...
safe=$(echo "$subdomain" | tr '/: ' '___')
if curl -s --connect-timeout 5 "http://$subdomain" >/dev/null || curl -s --connect-timeout 5 "https://$subdomain" >/dev/null; then
  nmap -Pn -p- "$subdomain" -oN "output/${safe}_ports.txt"
  nmap -Pn --script vuln -oX "output/${safe}_vuln.xml" "$subdomain"
  # parse XML with python or xmlstarlet
fi
...
rm -f "$temp"
```

---

## Contoh output yang diharapkan (`output/critical_vulns.txt`)
Tab-separated text, contoh:
```
Subdomain	Vuln Name	Severity	CVE
example.com	SSL certificate uses weak signature	CRITICAL	CVE-YYYY-XXXX
api.example.com	Outdated OpenSSL	HIGH	CVE-2018-YYYY
```

---

## Catatan hukum & etika
**Jangan** memindai target tanpa izin. Pastikan kamu memiliki otorisasi tertulis atau jalankan hanya di lingkungan lab/test milikmu.

---

Jika kamu mau, saya bisa:
- Mengubah README ini jadi **English** (agar sesuai repo utama).  
- Membuat file `scan_subdomains.README.md` di folder `/mnt/data/` agar bisa kamu download langsung.  
- Atau langsung **menghasilkan versi script** yang sudah diperbaiki (XML parsing + sanitasi) dan export ke file.

Pilih salah satu dan saya akan ekspor sekarang.
