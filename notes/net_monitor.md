

# 📘 Understanding `net_monitor.sh` 

**Author:** Anup Chapain
**Repository:** linux-scripting-repo

---

## 1. Introduction

The `net_monitor.sh` script is a **production-grade network monitoring tool** that:

* Monitors real-time network usage
* Logs activity for analysis
* Generates reports summarizing bandwidth usage
* Supports **`nethogs`** (per-process stats) and **`ss`** (socket-level stats)
* Provides **interactive options** and install prompts

**Use Cases:**

* DevOps interview prep
* Server/network monitoring in Linux
* Analyzing which processes consume the most bandwidth
* Debugging network issues

---

## 2. Shebang & Script Header

```bash
#!/usr/bin/env bash
```

* **Shebang** tells Linux which interpreter to use.
* `env` finds `bash` in your `$PATH`, ensuring portability across Linux distributions.

The header also includes:

```bash
# Author: Anup Chapain
# Features, Usage, etc.
```

* Provides **documentation** for anyone reading the script.

---

## 3. Variables

```bash
LOGFILE=~/net_monitor.log
```

* Stores the **log file path**.
* `~` expands to the user's home directory.
* Later used in logging, reporting, and creating the file.

**Tip:** Use variables for paths or constants to make scripts maintainable.

---

## 4. Help Function

```bash
show_help() {
    cat <<EOF
    ...
EOF
}
```

* Uses `cat <<EOF ... EOF` **here-doc** to print multi-line text.
* Displays **usage instructions**, options, and features.

**Example usage:**

```bash
./net_monitor.sh -h
./net_monitor.sh --help
```

---

## 5. Monitor Network Function

```bash
monitor_network() { ... }
```

**Key steps inside:**

### 5.1 Directory & File Creation

```bash
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
```

* `mkdir -p` → ensures the directory exists
* `dirname` → extracts directory part of path
* `touch` → creates the log file if it doesn’t exist

### 5.2 Tool Availability Check

```bash
HAS_NETHOGS=false
HAS_SS=false
command -v nethogs &>/dev/null && HAS_NETHOGS=true
command -v ss &>/dev/null && HAS_SS=true
```

* `command -v` → checks if a command exists
* `&>/dev/null` → silences output
* Sets boolean flags to guide interactive choices

### 5.3 Interactive Tool Selection

```bash
echo "1) nethogs"
echo "2) ss"
read -rp "Choice [1/2]: " choice
```

* `read -rp` → prompts user and reads input
* Interactive choice improves usability

### 5.4 Conditional Execution

```bash
case "$choice" in
    1) ... ;;
    2) ... ;;
    *) ... ;;
esac
```

* **Case statement** handles user input gracefully
* Executes `run_nethogs` or `use_ss` based on choice

---

## 6. Running Nethogs

```bash
run_nethogs() {
    sudo nethogs -t 2>&1 | while read -r line; do
        echo "TIMESTAMP: $(date) | $line" | tee -a "$LOGFILE"
    done
}
```

**Concepts:**

* `sudo nethogs -t` → runs nethogs in text mode
* `2>&1` → redirects stderr to stdout
* `while read -r line; do ... done` → processes output line by line
* Prefixing each line with `TIMESTAMP: $(date)` ensures logs are timestamped
* `tee -a` → appends to file **and** prints to terminal

**Tip:** Always log timestamps for later analysis.

---

## 7. Installing Nethogs

```bash
install_nethogs() {
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y nethogs
    elif command -v yum &>/dev/null; then
        sudo yum install -y nethogs
    else
        echo "Unknown package manager. Install manually."
    fi
}
```

**Concepts:**

* Detects package manager automatically
* `&&` ensures sequential execution
* `-y` flag for **non-interactive install**

**Troubleshooting:**

* If `apt` or `yum` isn’t available, user must install manually.

---

## 8. Fallback Monitoring: ss

```bash
use_ss() {
    while true; do
        echo "TIMESTAMP: $(date)" | tee -a "$LOGFILE"
        ss -tunap 2>&1 | tee -a "$LOGFILE"
        sleep 5
    done
}
```

**ss Options Explained:**

* `-t` → TCP
* `-u` → UDP
* `-n` → numeric (don’t resolve hostnames)
* `-a` → all sockets (listening + established)
* `-p` → show process using socket

**Loop & Sleep:**

* Infinite `while true` loop monitors continuously
* `sleep 5` → pauses 5 seconds between snapshots

**Tip:** `ss` is faster and more modern than `netstat`.

---

## 9. Generating Report

```bash
generate_report() { ... }
```

**Steps Explained:**

### 9.1 Check Log File

```bash
if [[ ! -f "$LOGFILE" ]]; then
    echo "No log file found"
    exit 1
fi
```

* Ensures the log exists before analyzing

### 9.2 Nethogs Analysis

```bash
grep "KB/sec" "$LOGFILE" | awk '{key=$2" "$3; kb=$NF; total[key]+=kb} END {...}'
```

* **grep** → filters lines containing `KB/sec`

* **awk** → powerful text processing tool:

  * `$2` → process name
  * `$3` → PID
  * `$NF` → last field (KB/sec)
  * `total[key]+=kb` → aggregates bandwidth

* Sort, take top 10, print nicely

**Other Metrics:**

* Top users: `$1` (username)
* Peak bandwidth timeline: sort by `$NF` descending

---

### 9.3 SS Analysis

```bash
awk '/ESTAB|LISTEN/ {split($5,a,":"); print a[1]}' "$LOGFILE"
```

* Extracts **remote IPs**
* Uses `split` to separate IP and port
* Filters IPv4 using regex `^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$`
* Sort + `uniq -c` → frequency of connections

**Protocol Usage:**

```bash
awk '/tcp|udp/ {print $1}' "$LOGFILE" | sort | uniq -c | sort -nr
```

* Shows top protocols in use

---

### 9.4 Timeline of Monitoring Sessions

```bash
grep -F -- "TIMESTAMP:" "$LOGFILE" | sed 's/TIMESTAMP: //'
```

* `-F` → fixed string (avoids interpreting dashes as options)
* `sed` → removes prefix for cleaner output

---

## 10. Main Program Logic

```bash
case "$1" in
    -h|--help) show_help ;;
    --report) generate_report ;;
    "") monitor_network ;;
    *) echo "Invalid option" ;;
esac
```

* Handles **CLI arguments** gracefully
* Defaults to **interactive monitoring** if no arguments

---

## 11. Core Linux Commands Used

| Command                   | Description                           | Use Case                                 |
| ------------------------- | ------------------------------------- | ---------------------------------------- |
| `mkdir -p`                | Create directories, including parents | Ensure log folder exists                 |
| `touch`                   | Create empty file                     | Initialize log file                      |
| `command -v`              | Check if command exists               | Verify availability of `nethogs` or `ss` |
| `read -rp`                | Read user input interactively         | Tool selection                           |
| `sudo nethogs -t`         | Monitor per-process bandwidth         | Real-time monitoring                     |
| `ss -tunap`               | Show socket connections               | Fallback monitoring                      |
| `tee -a`                  | Append to log and show output         | Logging                                  |
| `grep`                    | Filter lines matching pattern         | Extract relevant logs                    |
| `awk`                     | Field-wise processing                 | Summarize usage                          |
| `sort`, `uniq -c`, `head` | Aggregate and filter top items        | Top processes/IPs                        |
| `sed`                     | Stream editor                         | Clean timestamps for report              |

---

## 12. Troubleshooting Tips

| Issue                   | Likely Cause                    | Fix                        |
| ----------------------- | ------------------------------- | -------------------------- |
| `nethogs not found`     | Not installed                   | `sudo apt install nethogs` |
| `permission denied`     | No sudo                         | Run script with `sudo`     |
| Log file empty          | Script not run or misconfigured | Check `LOGFILE` path       |
| Wrong timestamp parsing | Missing `-F` in grep            | Use `grep -F`              |
| Infinite loop CPU usage | Sleep too low                   | Increase `sleep` interval  |

---

## 13. Summary & Key Takeaways

* Modular Bash scripting: **functions, case statements, variables**
* Logging: **timestamps + `tee` for dual output**
* Network monitoring: **`nethogs` for per-process, `ss` for sockets**
* Log analysis: **`awk + grep + sort + uniq`** for reports
* Interactive UX: **install prompts, tool choice**
* Production-ready script: maintainable and extensible.

---
