#!/usr/bin/env bash
# wordpress_doctor.sh
#
# WordPress Doctor – Diagnose, Fix, Install, and Status Check Tool
#
# Features:
#   * Diagnose common WordPress issues (config, DB, PHP, permissions)
#   * Fix issues interactively (permissions, DB connection, missing deps)
#   * Install WordPress if not found (on Ubuntu/Debian systems)
#   * Check service status (Apache, MySQL, PHP)
#   * Beginner-friendly with clear prompts and logging
#
# Usage:
#   ./wordpress_doctor.sh /path/to/wordpress   # Diagnose specific WordPress
#   ./wordpress_doctor.sh --fix /path/to/wp    # Diagnose & attempt fixes
#   ./wordpress_doctor.sh --install            # Install WordPress fresh
#   ./wordpress_doctor.sh --status             # Check service status
#   ./wordpress_doctor.sh -h | --help          # Show help
#
# Author: Anup Chapain

LOGFILE="$HOME/wordpress_doctor.log"

# ------------------------------------------------------------
# Function: log
# Write messages to terminal and logfile with timestamp
# ------------------------------------------------------------
log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOGFILE"
}

# ------------------------------------------------------------
# Function: show_help
# Display usage instructions
# ------------------------------------------------------------
show_help() {
    cat <<EOF
WordPress Doctor – Diagnose and Fix Tool
----------------------------------------

USAGE:
  ./wordpress_doctor.sh /path/to/wordpress
  ./wordpress_doctor.sh --fix /path/to/wordpress
  ./wordpress_doctor.sh --install
  ./wordpress_doctor.sh --status
  ./wordpress_doctor.sh -h | --help

OPTIONS:
  --fix DIR      Diagnose and attempt to fix WordPress at DIR
  --install      Install a fresh WordPress site
  --status       Check status of Apache, MySQL, and PHP
  -h, --help     Show this help message

FEATURES:
  * Diagnose wp-config.php and DB settings
  * Check PHP, MySQL, permissions
  * Interactive fixes
  * Auto-install WordPress if missing
  * Service status check
EOF
}

# ------------------------------------------------------------
# Function: install_wordpress
# Fresh installation of WordPress (Ubuntu/Debian style)
# ------------------------------------------------------------
install_wordpress() {
    log "📦 Installing WordPress and dependencies..."

    if ! command -v apache2 >/dev/null 2>&1; then
        log "➡ Installing Apache2..."
        sudo apt update && sudo apt install -y apache2
    fi

    if ! command -v mysql >/dev/null 2>&1; then
        log "➡ Installing MySQL server..."
        sudo apt install -y mysql-server
        sudo systemctl enable --now mysql
    fi

    if ! command -v php >/dev/null 2>&1; then
        log "➡ Installing PHP and extensions..."
        sudo apt install -y php php-mysql libapache2-mod-php php-cli php-curl php-xml
    fi

    # Download WordPress
    log "➡ Downloading latest WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp/

    # Deploy to /var/www/html/wordpress
    sudo rm -rf /var/www/html/wordpress
    sudo mv /tmp/wordpress /var/www/html/wordpress
    sudo chown -R www-data:www-data /var/www/html/wordpress

    log "✔ WordPress installed at /var/www/html/wordpress"
    log "👉 Now run: ./wordpress_doctor.sh /var/www/html/wordpress"
}

# ------------------------------------------------------------
# Function: check_wordpress
# Diagnose WordPress directory
# ------------------------------------------------------------
check_wordpress() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        log "❌ Directory $dir does not exist."
        exit 1
    fi

    if [[ ! -f "$dir/wp-config.php" ]]; then
        log "❌ wp-config.php missing in $dir"
        exit 1
    fi

    log "✔ Found WordPress at $dir"
    log "🔍 Starting diagnosis..."

    # Check PHP
    if ! command -v php >/dev/null 2>&1; then
        log "❌ PHP not installed."
        return 1
    else
        log "✔ PHP is installed: $(php -v | head -n1)"
    fi

    # Check MySQL
    if ! command -v mysql >/dev/null 2>&1; then
        log "❌ MySQL not installed."
        return 1
    else
        log "✔ MySQL is installed: $(mysql --version)"
    fi

    # Extract DB info
    DB_NAME=$(grep "DB_NAME" "$dir/wp-config.php" | cut -d "'" -f4)
    DB_USER=$(grep "DB_USER" "$dir/wp-config.php" | cut -d "'" -f4)
    DB_PASS=$(grep "DB_PASSWORD" "$dir/wp-config.php" | cut -d "'" -f4)

    log "📂 DB_NAME=$DB_NAME, DB_USER=$DB_USER"

    # Test DB connection
    mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        log "✔ Database connection successful."
    else
        log "❌ Database connection failed."
        return 1
    fi

    # Permissions
    if [[ $(stat -c "%U:%G" "$dir") != "www-data:www-data" ]]; then
        log "⚠ Permissions not set correctly on $dir"
        return 1
    else
        log "✔ Permissions look good."
    fi

    log "✅ Diagnosis complete. No critical issues found."
    return 0
}

# ------------------------------------------------------------
# Function: fix_wordpress
# Attempt to fix common issues
# ------------------------------------------------------------
fix_wordpress() {
    local dir="$1"

    log "🛠 Attempting to fix WordPress at $dir..."

    # Fix PHP
    if ! command -v php >/dev/null 2>&1; then
        log "➡ Installing PHP..."
        sudo apt install -y php php-mysql
    fi

    # Fix MySQL
    if ! command -v mysql >/dev/null 2>&1; then
        log "➡ Installing MySQL..."
        sudo apt install -y mysql-server
        sudo systemctl enable --now mysql
    fi

    # Fix permissions
    sudo chown -R www-data:www-data "$dir"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
    log "✔ Permissions reset."

    log "👉 If DB issues persist, check wp-config.php manually."
}

# ------------------------------------------------------------
# Function: status_check
# Check status of Apache, MySQL, PHP
# ------------------------------------------------------------
status_check() {
    log "============================================================"
    log "📊 WordPress Environment Status"
    log "============================================================"

    for svc in apache2 mysql php-fpm; do
        if systemctl list-units --type=service | grep -q "$svc"; then
            if systemctl is-active --quiet "$svc"; then
                log "✔ $svc is running"
            else
                log "❌ $svc is installed but not running"
            fi
        else
            log "⚠ $svc not installed"
        fi
    done

    log "============================================================"
}

# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    --install)
        install_wordpress
        ;;
    --fix)
        if [[ -z "$2" ]]; then
            log "❌ No WordPress directory specified."
            log "👉 Try: ./wordpress_doctor.sh --fix /var/www/html/wordpress"
            exit 1
        fi
        fix_wordpress "$2"
        ;;
    --status)
        status_check
        ;;
    --check|"")
        if [[ -z "$2" && -z "$1" ]]; then
            log "❌ No WordPress directory specified."
            log "👉 Try: ./wordpress_doctor.sh /var/www/html/wordpress"
            exit 1
        fi
        check_wordpress "$2"
        ;;
    *)
        # If a directory is passed directly
        check_wordpress "$1"
        ;;
esac
