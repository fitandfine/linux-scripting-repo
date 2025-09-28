

# 🩺 Net Doctor — Linux Networking Troubleshooting Guide

Author: **Anup Chapain**
---

## 📌 Introduction

The `net_doctor.sh` script is an **interactive Linux networking diagnostic tool**.
It is designed for beginners who want to:

* Check internet connectivity
* Diagnose DNS resolution issues
* Inspect default gateways and routing
* Scan open ports on localhost
* Test remote host reachability
* Generate simple logs for troubleshooting

This guide explains **every command and concept** used in the script, with examples and troubleshooting tips.

---

## ⚙️ Features of `net_doctor.sh`

* `--help` → Show usage instructions.
* `--check` → Run **basic connectivity tests**.
* `--diagnose` → Run **extended network diagnostics**.
* `--ports` → Scan open ports on your machine.
* `--report` → Save a **diagnostic report** to `~/net_doctor.log`.

---

## 🧩 Concepts and Commands Used

### 1. **Basic Connectivity — `ping`**

```bash
ping -c 4 8.8.8.8
```

* Sends **ICMP echo requests** to `8.8.8.8` (Google DNS).
* `-c 4` → limit to 4 packets.
* If successful → your machine has basic internet connectivity.
* If it fails → possible problems:

  * Network cable disconnected
  * Wi-Fi down
  * Router issue
  * ISP outage

💡 Troubleshooting: If `ping 8.8.8.8` works but `ping google.com` fails → DNS issue.

---

### 2. **DNS Resolution — `dig` or `nslookup`**

```bash
dig google.com +short
```

* Resolves a domain to an IP address using DNS.
* `+short` → cleaner output (just the IPs).

Alternative:

```bash
nslookup google.com
```

* Gives detailed DNS resolution info.

---

### 3. **Default Gateway & Routing — `ip route`**

```bash
ip route | grep default
```

* Displays the **default gateway** (the router your system sends traffic to).
* If empty → no internet access.

Example output:

```
default via 192.168.1.1 dev wlan0
```

* Means all traffic goes to `192.168.1.1` (your router).

---

### 4. **Network Interfaces — `ip addr`**

```bash
ip addr show
```

* Lists all **network interfaces** and their IPs.
* Example:

  ```
  2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
      inet 192.168.1.100/24
  ```
* Tells you if your system has a valid **private IP**.

---

### 5. **Port Scanning — `ss`**

```bash
ss -tuln
```

* Lists open sockets (ports).
* Flags:

  * `t` → TCP
  * `u` → UDP
  * `l` → Listening
  * `n` → Don’t resolve hostnames (faster, numeric only)

Example:

```
LISTEN 0 128 *:22 *:*   # SSH
LISTEN 0 80  *:80 *:*   # Web server (HTTP)
```

---

### 6. **Remote Host Check — `ping` again**

```bash
ping -c 2 google.com
```

* Confirms whether DNS + routing + connectivity to the outside world works.

---

### 7. **Logging — `tee`**

```bash
command | tee -a "$LOGFILE"
```

* Runs a command and **writes output to a log file** while still showing it in the terminal.
* Useful for audits or ISP troubleshooting.

---

### 8. **Case Switch — Script Arguments**

```bash
case "$1" in
    --help) show_help ;;
    --check) run_basic_tests ;;
    --diagnose) run_diagnostics ;;
    --ports) run_port_scan ;;
    --report) generate_report ;;
    *) echo "Unknown option: $1"; show_help ;;
esac
```

* Makes script **interactive with flags**.
* Beginner-friendly: you just run `./net_doctor.sh --check`.

---

## 🛠 Example Runs

### Check connectivity

```bash
./net_doctor.sh --check
```

Output:

```
🌐 Pinging Google DNS...
✔ Internet is reachable
🔎 Checking DNS resolution...
✔ DNS working: google.com -> 142.250.72.14
```

### Diagnose full network

```bash
./net_doctor.sh --diagnose
```

Output:

```
🩺 Running extended diagnostics...
🌐 Default gateway: 192.168.1.1
🔗 Interfaces:
    eth0 -> 192.168.1.10
```

### Scan open ports

```bash
./net_doctor.sh --ports
```

Output:

```
🔍 Open ports:
LISTEN 0 128 *:22 *:*  # SSH
LISTEN 0 80  *:80 *:*  # Apache/Nginx
```

### Generate report

```bash
./net_doctor.sh --report
```

Output:

```
============================================================
📋 Net Doctor Report
============================================================
🌐 Internet is reachable
✔ DNS working: google.com -> 142.250.72.14
🛜 Default gateway: 192.168.1.1
...
Report saved at: /home/anup/net_doctor.log
```

---

## 🧯 Troubleshooting Tips

* `ping: command not found` → install `iputils-ping`.
* `dig: command not found` → install `dnsutils`.
* No default gateway? → Restart networking:

  ```bash
  sudo systemctl restart NetworkManager
  ```
* Port scan empty but services running? → Check firewall:

  ```bash
  sudo ufw status
  ```

---

## 📚 Revision Checklist

* [x] Ping for connectivity
* [x] DNS troubleshooting with `dig`
* [x] Check default gateway with `ip route`
* [x] List network interfaces with `ip addr`
* [x] Scan open ports with `ss -tuln`
* [x] Generate logs with `tee`
* [x] Case switch for interactive options

---
