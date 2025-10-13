#!/usr/bin/env bash
# nginx_diagnose.sh
# A comprehensive Nginx troubleshooting script for DevOps engineers
#
# Usage:
#   sudo ./nginx_diagnose.sh           # run diagnostics
#   ./nginx_diagnose.sh --help | -h    # show help
#
# Description:
#   - Checks Nginx installation, service status, configuration, logs, and network bindings.
#   - Provides interactive suggestions for troubleshooting.
#   - Saves a detailed report for later review.
#   - Offers troubleshooting tips at the end.
#   - Includes advanced checks (SELinux, memory, multiple processes, log dir perms).
#
# Author: Anup Chapain

#------------------------------------------------------------
# Handle --help / -h option
#------------------------------------------------------------
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<EOF
Nginx Troubleshooting & Diagnostics Tool
----------------------------------------
This script checks and troubleshoots Nginx installation and runtime issues.

USAGE:
  sudo ./nginx_diagnose.sh

OPTIONS:
  -h, --help   Show this help message and exit.

WHAT IT DOES:
  * Checks if Nginx is installed
  * Verifies service status
  * Validates configuration syntax
  * Displays version/build info
  * Checks listening ports
  * Verifies firewall rules
  * Analyzes recent logs
  * Tests HTTP/HTTPS connectivity
  * Checks disk and memory usage
  * Verifies SELinux & log directory permissions
  * Suggests troubleshooting tips

EOF
    exit 0
fi

#------------------------------------------------------------
# Create logfile name with timestamp and store in /tmp
#------------------------------------------------------------
LOGFILE="/tmp/nginx_diagnose_$(date +%F_%H-%M-%S).log"

# Variables for issue tracking
ISSUE_SERVICE="OK"
ISSUE_CONFIG="OK"
ISSUE_PORTS="OK"
ISSUE_FIREWALL="OK"
ISSUE_CONNECTIVITY="OK"
ISSUE_SELINUX="OK"
ISSUE_PERMS="OK"
ISSUE_MEMORY="OK"

#------------------------------------------------------------
# Print the banner header
#------------------------------------------------------------
echo "============================================================"
echo "        Nginx Troubleshooting & Diagnostics Tool"
echo "============================================================"
echo "Log file: $LOGFILE"
echo "------------------------------------------------------------"

#------------------------------------------------------------
# Helper functions
#------------------------------------------------------------

# Function: log_and_print
#   Prints to screen and log file
log_and_print() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Function: check_command
#   Returns true if command exists in PATH
check_command() {
    command -v "$1" >/dev/null 2>&1
}

#------------------------------------------------------------
# 1. Check if Nginx is installed
#------------------------------------------------------------
log_and_print "\n[1] Checking if Nginx is installed..."
if check_command nginx; then
    NGINX_BIN=$(command -v nginx)
    log_and_print "✔ Nginx binary found: $NGINX_BIN"
else
    log_and_print "✘ Nginx is not installed."
    read -p "Do you want to install Nginx now? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        if check_command apt; then
            sudo apt update && sudo apt install -y nginx
        elif check_command yum; then
            sudo yum install -y epel-release && sudo yum install -y nginx
        fi
    fi
    exit 1
fi

#------------------------------------------------------------
# 2. Check Nginx service status
#------------------------------------------------------------
log_and_print "\n[2] Checking Nginx service status..."
if systemctl is-active --quiet nginx; then
    log_and_print "✔ Nginx is running."
else
    log_and_print "✘ Nginx is not running."
    ISSUE_SERVICE="Nginx service is not running"
    read -p "Do you want to try starting Nginx? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        sudo systemctl start nginx
        systemctl status nginx | tee -a "$LOGFILE"
    fi
fi

#------------------------------------------------------------
# 3. Show Nginx version and build options
#------------------------------------------------------------
log_and_print "\n[3] Nginx version and build info:"
nginx -V 2>&1 | tee -a "$LOGFILE"

#------------------------------------------------------------
# 4. Test configuration syntax
#------------------------------------------------------------
log_and_print "\n[4] Validating Nginx configuration..."
if nginx -t 2>&1 | tee -a "$LOGFILE"; then
    log_and_print "✔ Configuration syntax is valid."
else
    log_and_print "✘ Configuration has errors. Please review above."
    ISSUE_CONFIG="Configuration syntax errors"
fi

#------------------------------------------------------------
# 5. Check listening ports
#------------------------------------------------------------
log_and_print "\n[5] Checking listening ports..."
if ss -tulpn | grep -q nginx; then
    ss -tulpn | grep nginx | tee -a "$LOGFILE"
else
    log_and_print "✘ No active Nginx bindings found."
    ISSUE_PORTS="No ports (80/443) are listening"
fi

#------------------------------------------------------------
# 6. Check firewall rules
#------------------------------------------------------------
log_and_print "\n[6] Checking firewall rules (common ports 80/443)..."
if check_command ufw; then
    if sudo ufw status | grep -q "80\|443"; then
        sudo ufw status numbered | tee -a "$LOGFILE"
    else
        log_and_print "✘ Firewall may be blocking HTTP/HTTPS."
        ISSUE_FIREWALL="Firewall may be blocking ports"
    fi
elif check_command firewall-cmd; then
    if sudo firewall-cmd --list-ports | grep -q "80\|443"; then
        sudo firewall-cmd --list-all | tee -a "$LOGFILE"
    else
        log_and_print "✘ Firewall may be blocking HTTP/HTTPS."
        ISSUE_FIREWALL="Firewall may be blocking ports"
    fi
else
    log_and_print "⚠ No firewall management tool detected (ufw/firewalld)."
fi

#------------------------------------------------------------
# 7. Logs analysis
#------------------------------------------------------------
log_and_print "\n[7] Checking logs for recent errors..."
ERROR_LOG="/var/log/nginx/error.log"
ACCESS_LOG="/var/log/nginx/access.log"

if [[ -f "$ERROR_LOG" ]]; then
    log_and_print "Recent Nginx error log entries:"
    tail -n 20 "$ERROR_LOG" | tee -a "$LOGFILE"
else
    log_and_print "No error log found at $ERROR_LOG"
fi

if [[ -f "$ACCESS_LOG" ]]; then
    log_and_print "\nRecent Nginx access log entries:"
    tail -n 20 "$ACCESS_LOG" | tee -a "$LOGFILE"
else
    log_and_print "No access log found at $ACCESS_LOG"
fi

#------------------------------------------------------------
# 8. Test local connectivity
#------------------------------------------------------------
log_and_print "\n[8] Testing local HTTP/HTTPS connectivity..."
for url in "http://localhost" "https://localhost"; do
    if curl -k -s -o /dev/null -w "%{http_code}" "$url" | grep -qE "200|301|302"; then
        log_and_print "✔ $url is responding."
    else
        log_and_print "✘ $url is not responding properly."
        ISSUE_CONNECTIVITY="Local HTTP/HTTPS test failed"
    fi
done

#------------------------------------------------------------
# 9. Check disk usage
#------------------------------------------------------------
log_and_print "\n[9] Checking disk usage..."
df -h | tee -a "$LOGFILE"

#------------------------------------------------------------
# 10. Extra Checks (Memory, SELinux, Permissions, Processes)
#------------------------------------------------------------
log_and_print "\n[10] Extra Checks..."

# Memory usage of nginx processes
if pgrep nginx >/dev/null; then
    log_and_print "Nginx memory/CPU usage:"
    ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | grep nginx | tee -a "$LOGFILE"
    MEM_HIGH=$(ps -o %mem --no-headers -C nginx | awk '{sum+=$1} END {if(sum>70) print "HIGH"}')
    if [[ "$MEM_HIGH" == "HIGH" ]]; then
        ISSUE_MEMORY="Nginx is consuming high memory (>70%)"
    fi
fi

# Multiple instances check
if [[ $(pgrep -c nginx) -gt 10 ]]; then
    log_and_print "⚠ High number of Nginx worker processes detected."
fi

# SELinux check
if check_command getenforce; then
    if [[ "$(getenforce)" == "Enforcing" ]]; then
        ISSUE_SELINUX="SELinux is enforcing, may block Nginx"
        log_and_print "⚠ SELinux is enforcing. May restrict Nginx."
    else
        log_and_print "✔ SELinux not restricting Nginx."
    fi
fi

# Log directory permissions
if [[ -d "/var/log/nginx" && ! -w "/var/log/nginx" ]]; then
    ISSUE_PERMS="Nginx log directory not writable"
    log_and_print "✘ Nginx log directory permissions issue."
fi

#------------------------------------------------------------
# 11. Summary and Troubleshooting Tips
#------------------------------------------------------------
log_and_print "\n============================================================"
log_and_print "Diagnostics complete. Report saved to: $LOGFILE"
log_and_print "============================================================"

log_and_print "\n📌 Troubleshooting Tips:"
if [[ "$ISSUE_SERVICE" != "OK" ]]; then
    log_and_print " - $ISSUE_SERVICE → Try: sudo systemctl restart nginx && systemctl status nginx"
fi
if [[ "$ISSUE_CONFIG" != "OK" ]]; then
    log_and_print " - $ISSUE_CONFIG → Fix syntax: sudo nginx -t && sudo systemctl reload nginx"
fi
if [[ "$ISSUE_PORTS" != "OK" ]]; then
    log_and_print " - $ISSUE_PORTS → Ensure no other service (Apache) is using port 80/443. Use: sudo lsof -i :80"
fi
if [[ "$ISSUE_FIREWALL" != "OK" ]]; then
    log_and_print " - $ISSUE_FIREWALL → Open ports: sudo ufw allow 80/tcp && sudo ufw allow 443/tcp"
fi
if [[ "$ISSUE_CONNECTIVITY" != "OK" ]]; then
    log_and_print " - $ISSUE_CONNECTIVITY → Check logs in /var/log/nginx/, ensure DNS resolves correctly."
fi
if [[ "$ISSUE_SELINUX" != "OK" ]]; then
    log_and_print " - $ISSUE_SELINUX → Temporarily set permissive: sudo setenforce 0 (not for prod)."
fi
if [[ "$ISSUE_PERMS" != "OK" ]]; then
    log_and_print " - $ISSUE_PERMS → Fix: sudo chown -R www-data:www-data /var/log/nginx"
fi
if [[ "$ISSUE_MEMORY" != "OK" ]]; then
    log_and_print " - $ISSUE_MEMORY → Consider tuning worker_processes / worker_connections in nginx.conf."
fi

if [[ "$ISSUE_SERVICE" == "OK" && "$ISSUE_CONFIG" == "OK" && "$ISSUE_PORTS" == "OK" && \
      "$ISSUE_FIREWALL" == "OK" && "$ISSUE_CONNECTIVITY" == "OK" && \
      "$ISSUE_SELINUX" == "OK" && "$ISSUE_PERMS" == "OK" && "$ISSUE_MEMORY" == "OK" ]]; then
    log_and_print "✔ No critical issues detected. Nginx appears healthy."
fi
