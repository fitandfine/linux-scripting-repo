

# 🐧 Linux Command Guide — Complete Beginner to Advanced

Author: **Anup Chapain**
---

## 📌 Introduction

Linux is a **command-driven operating system**, meaning you can control and automate everything from the terminal.

This guide is **self-sustaining** — if you carefully study it, you’ll be able to:

* Operate Linux as a **desktop user** (file handling, basic commands)
* Manage Linux as a **system administrator** (users, services, processes, monitoring)
* Run Linux as a **server administrator** (networking, security, troubleshooting)
* Write scripts and use **command-line operators** to combine commands like Lego blocks

---

# 🧩 Chapter 1: File and Directory Management

### 1.1 `pwd` — Print Working Directory

Shows the full path of the current directory.

```bash
pwd
```

---

### 1.2 `ls` — List Files

```bash
ls          # simple list
ls -l       # long format (permissions, owner, size, date)
ls -a       # show hidden files
ls -lh      # human-readable sizes
ls -ltr     # sort by time, newest last
```

💡 Use case: Quickly check hidden config files (`.bashrc`, `.gitignore`).

---

### 1.3 `cd` — Change Directory

```bash
cd /etc
cd ~        # home directory
cd ..       # parent folder
cd -        # jump back to previous directory
```

---

### 1.4 `touch` — Create File

```bash
touch notes.txt
```

---

### 1.5 `mkdir` — Create Directory

```bash
mkdir new_folder
mkdir -p parent/child/grandchild   # recursive create
```

---

### 1.6 `cp` — Copy Files

```bash
cp file1.txt file2.txt
cp -r dir1 dir2   # copy folders recursively
```

---

### 1.7 `mv` — Move/Rename

```bash
mv file.txt /tmp/
mv oldname.txt newname.txt
```

---

### 1.8 `rm` — Remove Files

```bash
rm file.txt
rm -r folder/        # delete folder and contents
rm -rf folder/       # force delete (⚠ dangerous!)
```

---

### 1.9 `find` — Locate Files

Find by name:

```bash
find /etc -name "*.conf"
```

Find by size:

```bash
find . -size +100M      # larger than 100MB
find . -size -1M        # smaller than 1MB
```

Find by modified time:

```bash
find . -mtime -1        # modified within last 24h
find . -mtime +7        # older than 7 days
```

Find and delete:

```bash
find /tmp -type f -name "*.log" -delete
```

💡 Use case: Clean up old logs, identify large files.

---

### 1.10 Redirection & Pipes (`>`, `>>`, `<`, `|`, `&`, `&&`, `||`)

* `>` → overwrite output to file
* `>>` → append output to file
* `<` → take input from file
* `|` → pipe output of one command into another
* `&` → run in background
* `&&` → run second command only if first succeeds
* `||` → run second command only if first fails

Examples:

```bash
echo "Hello" > file.txt      # overwrite file
echo "World" >> file.txt     # append to file
sort < file.txt              # input redirection
cat file.txt | grep error    # pipe to grep
ls &                         # run in background
mkdir test && cd test        # only cd if mkdir worked
ping -c 1 google.com || echo "Network down"
```

---

# 🧩 Chapter 2: Viewing & Searching Files

### 2.1 `cat`, `less`, `more`

```bash
cat file.txt
less /var/log/syslog
```

Navigation in `less`:

* `q` → quit
* `/word` → search
* `n` → next search result

---

### 2.2 `head` & `tail`

```bash
head -n 20 file.txt   # first 20 lines
tail -n 50 file.txt   # last 50 lines
tail -f log.txt       # follow updates live
```

💡 Use case: Monitor logs in real time.

---

### 2.3 `grep` — Search Inside Files

```bash
grep "error" logfile.txt
grep -i "warning" logfile.txt   # case-insensitive
grep -r "fail" /var/log         # recursive search
grep -n "main" code.c           # show line numbers
grep -A2 -B2 "critical" log.txt # 2 lines before & after
```

💡 Use case: Diagnose issues in logs quickly.

---

### 2.4 `awk` — Extract Columns

```bash
awk '{print $1, $3}' file.txt
```

---

### 2.5 `sed` — Find & Replace

```bash
sed 's/error/issue/g' logfile.txt
```

---

# 🧩 Chapter 3: Users, Groups & Permissions

### 3.1 User Commands

```bash
whoami            # current user
id                # UID, GID
groups            # groups you belong to
```

Add users:

```bash
sudo adduser anup
sudo passwd anup
```

---

### 3.2 Permissions

```bash
ls -l file.txt
-rw-r--r--  1 user group 123 Jan 1 12:00 file.txt
```

* r = read
* w = write
* x = execute

Change permissions:

```bash
chmod 755 script.sh   # rwxr-xr-x
```

Change ownership:

```bash
chown anup:anup file.txt
```

---

# 🧩 Chapter 4: Processes & Monitoring

### 4.1 Process Management

```bash
ps aux | head -5
top
htop      # install: sudo apt install htop
```

Kill processes:

```bash
kill -9 PID
killall firefox
```

---

### 4.2 Resource Usage

```bash
uptime
df -h
du -sh /var/log
free -h
```

---

### 4.3 Logs

```bash
dmesg | tail
journalctl -u ssh --since "10 minutes ago"
```

---

# 🧩 Chapter 5: Networking

### 5.1 Basics

```bash
ping google.com
traceroute google.com   # install traceroute
```

---

### 5.2 Interfaces

```bash
ip addr show
ip route show
```

---

### 5.3 Ports & Connections

```bash
ss -tulnp
netstat -tulnp   # may need: sudo apt install net-tools
```

---

### 5.4 DNS

```bash
nslookup google.com
dig google.com ANY    # install dnsutils
```

---

### 5.5 File Transfer

```bash
scp file.txt user@server:/path/
rsync -av dir/ user@server:/backup/
```

---

# 🧩 Chapter 6: Services & System Control

### 6.1 systemctl

```bash
systemctl status apache2
sudo systemctl start apache2
sudo systemctl enable apache2
```

---

### 6.2 Shutdown & Reboot

```bash
sudo shutdown -h now
sudo reboot
```

---

# 🧩 Chapter 7: Archiving & Compression

```bash
tar -czvf archive.tar.gz dir/
tar -xvzf archive.tar.gz
gzip file.txt
gunzip file.txt.gz
zip archive.zip file1 file2
unzip archive.zip
```

---

# 🧩 Chapter 8: Security

### 8.1 UFW

```bash
sudo ufw enable
sudo ufw allow 22
sudo ufw status
```

### 8.2 Fail2ban

```bash
sudo apt install fail2ban
```

---

# 🧩 Chapter 9: Package Management

### Debian/Ubuntu

```bash
sudo apt update
sudo apt install nginx
sudo apt remove nginx
```

### RedHat/CentOS

```bash
sudo yum install nginx
```

---

# 🧩 Chapter 10: Operators & Shell Tricks

* `>` → write/overwrite
* `>>` → append
* `<` → read from file
* `|` → pipe to another command
* `;` → run sequentially
* `&&` → run if previous succeeds
* `||` → run if previous fails
* `&` → run in background

Examples:

```bash
ls /etc > list.txt
grep "root" /etc/passwd | wc -l
mkdir test && cd test
ping -c 1 google.com || echo "Network is down"
```

---

# 📚 Troubleshooting Tips

* **Permission denied** → Use `sudo` or `chmod +x`.
* **Command not found** → Install with `apt`, `yum`, or `pacman`.
* **Disk full** → Use `df -h` and `du -sh *` to find space hogs.
* **High CPU usage** → Use `top`/`htop` and `kill`.
* **Network issue** → Use `ping`, `traceroute`, `ss`.

---

# ✅ Quick Revision Cheatsheet

* Files: `ls`, `cd`, `cp`, `mv`, `rm`, `touch`, `find`
* Text: `cat`, `less`, `head`, `tail`, `grep`, `awk`, `sed`
* Users: `whoami`, `id`, `chmod`, `chown`, `groups`
* Processes: `ps`, `top`, `htop`, `kill`
* System: `df`, `du`, `free`, `uptime`, `dmesg`
* Networking: `ping`, `ip`, `ss`, `dig`, `ssh`, `scp`
* Services: `systemctl`, `journalctl`
* Security: `ufw`, `iptables`, `fail2ban`
* Archive: `tar`, `zip`, `gzip`
* Package: `apt`, `yum`, `dnf`, `pacman`
* Operators: `>`, `>>`, `<`, `|`, `&`, `&&`, `||`

---

