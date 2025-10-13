#!/usr/bin/env bash
# php_mysql_diagnose.sh
# A comprehensive PHP + MySQL/MariaDB troubleshooting tool for DevOps
#
# Author: Anup Chapain
# Usage:
#   sudo ./php_mysql_diagnose.sh          # Run diagnostics
#   ./php_mysql_diagnose.sh --help | -h   # Show help
#
# Description:
#   - Checks PHP installation, extensions, configuration, and version.
#   - Checks MySQL/MariaDB installation, service, users, permissions, and connectivity.
#   - Provides interactive suggestions for troubleshooting.
#   - Generates a log file for further inspection.
#   - Highlights common issues and fixes.

#------------------------------------------------------------
# Handle --help / -h option
#------------------------------------------------------------
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<EOF
PHP + MySQL Diagnostic Tool
---------------------------
This script checks PHP and MySQL/MariaDB installations, services,
configuration, extensions, logs, and connectivity.

USAGE:
  sudo ./php_mysql_diagnose.sh

OPTIONS:
  -h, --help   Show this help message and exit.

WHAT IT DOES:
  * Check if PHP is installed and working
  * Check installed PHP version
  * Check installed PHP extensions
  * Validate php.ini configuration
  * Check MySQL/MariaDB installation
  * Check MySQL service status
  * Test MySQL connection and user privileges
  * Check common PHP-MySQL connectivity issues
  * Check disk usage and logs
  * Provide troubleshooting tips

EOF
    exit 0
fi

#------------------------------------------------------------
# Create log file with timestamp
#------------------------------------------------------------
LOGFILE="/tmp/php_mysql_diagnose_$(date +%F_%H-%M-%S).log"

# Issue tracking variables (default "OK")
ISSUE_PHP="OK"
ISSUE_MYSQL="OK"
ISSUE_PHP_EXT="OK"
ISSUE_DB_CONN="OK"
ISSUE_CONFIG="OK"

#------------------------------------------------------------
# Helper function: log_and_print
#------------------------------------------------------------
log_and_print() {
    # Print string to screen and append to log file
    echo -e "$1" | tee -a "$LOGFILE"
}

# Helper function: check if command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

#------------------------------------------------------------
# Banner
#------------------------------------------------------------
echo "============================================================"
echo "        PHP + MySQL Diagnostic Tool"
echo "============================================================"
echo "Log file: $LOGFILE"
echo "------------------------------------------------------------"

#------------------------------------------------------------
# 1. Check if PHP is installed
#------------------------------------------------------------
log_and_print "\n[1] Checking PHP installation..."
if check_command php; then
    PHP_BIN=$(command -v php)
    PHP_VERSION=$(php -v | head -n1)
    log_and_print "✔ PHP binary found: $PHP_BIN"
    log_and_print "✔ PHP version: $PHP_VERSION"
else
    log_and_print "✘ PHP is not installed."
    ISSUE_PHP="PHP not installed"
    read -p "Do you want to install PHP now? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        if check_command apt; then
            sudo apt update && sudo apt install -y php php-mysql
        elif check_command yum; then
            sudo yum install -y php php-mysqlnd
        fi
    fi
    exit 1
fi

#------------------------------------------------------------
# 2. Check installed PHP extensions
#------------------------------------------------------------
log_and_print "\n[2] Checking PHP extensions..."
REQUIRED_EXTENSIONS=("mysqli" "pdo_mysql" "curl" "json" "mbstring")
for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if php -m | grep -q "^$ext$"; then
        log_and_print "✔ PHP extension $ext is installed."
    else
        log_and_print "✘ PHP extension $ext is missing."
        ISSUE_PHP_EXT="Some required PHP extensions missing"
    fi
done

#------------------------------------------------------------
# 3. Check php.ini configuration
#------------------------------------------------------------
log_and_print "\n[3] Checking php.ini configuration..."
PHP_INI=$(php --ini | grep "Loaded Configuration" | awk -F': ' '{print $2}')
if [[ -f "$PHP_INI" ]]; then
    log_and_print "✔ php.ini loaded: $PHP_INI"
else
    log_and_print "✘ Could not find php.ini"
    ISSUE_CONFIG="php.ini missing"
fi

#------------------------------------------------------------
# 4. Check MySQL/MariaDB installation
#------------------------------------------------------------
log_and_print "\n[4] Checking MySQL/MariaDB installation..."
if check_command mysql; then
    MYSQL_BIN=$(command -v mysql)
    log_and_print "✔ MySQL binary found: $MYSQL_BIN"
else
    log_and_print "✘ MySQL/MariaDB is not installed."
    ISSUE_MYSQL="MySQL not installed"
    read -p "Do you want to install MySQL/MariaDB now? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        if check_command apt; then
            sudo apt update && sudo apt install -y mysql-server
        elif check_command yum; then
            sudo yum install -y mariadb-server
        fi
    fi
    exit 1
fi

#------------------------------------------------------------
# 5. Check MySQL service status
#------------------------------------------------------------
log_and_print "\n[5] Checking MySQL service status..."
if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    log_and_print "✔ MySQL/MariaDB service is running."
else
    log_and_print "✘ MySQL/MariaDB service is not running."
    ISSUE_MYSQL="MySQL service not running"
    read -p "Do you want to start MySQL service? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        sudo systemctl start mysql || sudo systemctl start mariadb
        systemctl status mysql || systemctl status mariadb
    fi
fi

#------------------------------------------------------------
# 6. Test MySQL connection and privileges
#------------------------------------------------------------
log_and_print "\n[6] Testing MySQL connectivity..."
MYSQL_TEST_CMD="mysql -u root -e 'SELECT VERSION();'"
if $MYSQL_TEST_CMD >/dev/null 2>&1; then
    MYSQL_VERSION=$(mysql -u root -e "SELECT VERSION();" | head -n2 | tail -n1)
    log_and_print "✔ Successfully connected to MySQL. Version: $MYSQL_VERSION"
else
    log_and_print "✘ Cannot connect to MySQL with root user."
    ISSUE_DB_CONN="Cannot connect to MySQL"
    read -p "Do you want to attempt root login manually? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
        mysql -u root -p
    fi
fi

#------------------------------------------------------------
# 7. Check PHP-MySQL connection via CLI test
#------------------------------------------------------------
log_and_print "\n[7] Testing PHP-MySQL connection..."
PHP_TEST_CODE="<?php
\$conn = mysqli_connect('127.0.0.1','root','');
if (!\$conn) { echo 'Connection failed: '.mysqli_connect_error(); exit(1); }
echo '✔ PHP can connect to MySQL successfully';
mysqli_close(\$conn);
?>"
echo "$PHP_TEST_CODE" > /tmp/php_test_mysql.php
PHP_CONN_OUTPUT=$(php /tmp/php_test_mysql.php 2>&1)
log_and_print "$PHP_CONN_OUTPUT"
rm /tmp/php_test_mysql.php
if [[ "$PHP_CONN_OUTPUT" != *"successfully"* ]]; then
    ISSUE_DB_CONN="PHP cannot connect to MySQL"
fi

#------------------------------------------------------------
# 8. Check disk usage
#------------------------------------------------------------
log_and_print "\n[8] Checking disk usage..."
df -h | tee -a "$LOGFILE"

#------------------------------------------------------------
# 9. Check MySQL error logs
#------------------------------------------------------------
log_and_print "\n[9] Checking MySQL error logs..."
MYSQL_LOGS=("/var/log/mysql/error.log" "/var/log/mysqld.log" "/var/log/mysql.err")
for LOG in "${MYSQL_LOGS[@]}"; do
    if [[ -f "$LOG" ]]; then
        log_and_print "Last 20 lines of $LOG:"
        tail -n 20 "$LOG" | tee -a "$LOGFILE"
        break
    fi
done

#------------------------------------------------------------
# 10. Summary and Troubleshooting Tips
#------------------------------------------------------------
log_and_print "\n============================================================"
log_and_print "Diagnostics complete. Report saved to: $LOGFILE"
log_and_print "============================================================"

log_and_print "\n📌 Troubleshooting Tips:"
[[ "$ISSUE_PHP" != "OK" ]] && log_and_print " - $ISSUE_PHP → Install PHP: sudo apt install php php-mysql"
[[ "$ISSUE_PHP_EXT" != "OK" ]] && log_and_print " - $ISSUE_PHP_EXT → Install missing PHP extensions using your package manager."
[[ "$ISSUE_CONFIG" != "OK" ]] && log_and_print " - $ISSUE_CONFIG → Check php.ini configuration: php --ini"
[[ "$ISSUE_MYSQL" != "OK" ]] && log_and_print " - $ISSUE_MYSQL → Install/start MySQL/MariaDB service."
[[ "$ISSUE_DB_CONN" != "OK" ]] && log_and_print " - $ISSUE_DB_CONN → Check MySQL root password, user privileges, and PHP MySQL extension."

[[ "$ISSUE_PHP" == "OK" && "$ISSUE_PHP_EXT" == "OK" && "$ISSUE_CONFIG" == "OK" && "$ISSUE_MYSQL" == "OK" && "$ISSUE_DB_CONN" == "OK" ]] && \
log_and_print "✔ No critical issues detected. PHP and MySQL appear healthy."
