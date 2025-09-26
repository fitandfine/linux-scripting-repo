
# PHP + MySQL Complete Guide

## Table of Contents

1. [Introduction](#introduction)
2. [PHP Basics](#php-basics)

   * What is PHP
   * PHP Installation
   * PHP Configuration (`php.ini`)
   * PHP Syntax & Basic Examples
   * PHP Folder Structure
3. [MySQL Basics](#mysql-basics)

   * What is MySQL/MariaDB
   * Installation & Service Management
   * MySQL Folder Structure
   * Basic Commands
4. [PHP & MySQL Integration](#php--mysql-integration)

   * Connecting PHP to MySQL
   * CRUD Operations
   * Common Issues & Troubleshooting
5. [Advanced Administration](#advanced-administration)

   * Logs & Error Analysis
   * User Privileges & Security
   * Multiple Websites / Virtual Hosts
   * Performance Tuning
6. [Networking & DNS](#networking--dns)
7. [Summary & Best Practices](#summary--best-practices)
8. [References](#references)

---

## Introduction

PHP (Hypertext Preprocessor) is a server-side scripting language used to develop dynamic websites.
MySQL/MariaDB is a relational database management system (RDBMS) used to store and manage structured data.

Together, PHP + MySQL form the backbone of many web applications, including WordPress, Joomla, and custom solutions.

---

## PHP Basics

### What is PHP

* Server-side scripting language.
* Interpreted language, runs on web servers like Apache, Nginx.
* Used to generate dynamic HTML, handle forms, sessions, cookies, and database interactions.

### PHP Installation

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install php php-mysql php-cli php-curl php-mbstring php-json php-xml
php -v   # Check installed version
```

**CentOS/RHEL:**

```bash
sudo yum install epel-release
sudo yum install php php-mysqlnd php-cli php-curl php-mbstring php-json php-xml
php -v
```

### PHP Configuration (`php.ini`)

* Default location:

  * `/etc/php/<version>/cli/php.ini` (CLI)
  * `/etc/php/<version>/apache2/php.ini` (Apache)
* Key directives:

  * `display_errors` – Show errors on browser (development)
  * `error_log` – File path for logging errors
  * `upload_max_filesize` – Max file upload size
  * `memory_limit` – Maximum memory PHP scripts can use
  * `max_execution_time` – Max time a script can run

**Test PHP Installation:**
Create `/var/www/html/info.php` with:

```php
<?php
phpinfo();
?>
```

Access via browser: `http://localhost/info.php`

### PHP Folder Structure

```
/var/www/html/          # Default web root
/etc/php/<version>/     # Configuration files
/usr/bin/php            # CLI executable
/usr/lib/php/           # PHP modules and extensions
/var/log/php/           # Error logs
```

### PHP Syntax Example

```php
<?php
echo "Hello World!";
$name = "Anup";
echo "Welcome, $name!";
?>
```

---

## MySQL Basics

### What is MySQL/MariaDB

* Relational database to store structured data.
* MariaDB is a fork of MySQL, fully compatible.

### Installation & Service Management

**Ubuntu/Debian:**

```bash
sudo apt install mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl status mysql
```

**CentOS/RHEL:**

```bash
sudo yum install mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb
```

**Secure Installation:**

```bash
sudo mysql_secure_installation
```

### MySQL Folder Structure

```
/etc/mysql/            # Config files (my.cnf)
/var/lib/mysql/        # Database storage
/var/log/mysql/        # MySQL logs
/usr/bin/mysql         # CLI client
/usr/bin/mysqld        # MySQL daemon
```

### Basic Commands

```sql
-- Login
mysql -u root -p

-- Show databases
SHOW DATABASES;

-- Create database
CREATE DATABASE mydb;

-- Use database
USE mydb;

-- Create table
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50));

-- Insert data
INSERT INTO users (name) VALUES ('Anup');

-- Query data
SELECT * FROM users;

-- Update data
UPDATE users SET name='Anup Chapain' WHERE id=1;

-- Delete data
DELETE FROM users WHERE id=1;

-- Grant privileges
GRANT ALL PRIVILEGES ON mydb.* TO 'user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

---

## PHP & MySQL Integration

### Connecting PHP to MySQL

```php
<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mydb";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";
?>
```

### CRUD Operations via PHP

```php
// Create
$conn->query("INSERT INTO users (name) VALUES ('John Doe')");

// Read
$result = $conn->query("SELECT * FROM users");
while($row = $result->fetch_assoc()) {
    echo $row['name'];
}

// Update
$conn->query("UPDATE users SET name='Jane Doe' WHERE id=1");

// Delete
$conn->query("DELETE FROM users WHERE id=1");
```

### Common PHP-MySQL Issues

| Issue                        | Probable Cause            | Solution                                         |
| ---------------------------- | ------------------------- | ------------------------------------------------ |
| Can't connect to MySQL       | Wrong credentials or host | Check username/password, `bind-address` in MySQL |
| PHP mysqli extension missing | Not installed             | `sudo apt install php-mysql`                     |
| Access denied for user       | Privileges not set        | Grant proper privileges using `GRANT`            |
| MySQL server not running     | Service stopped           | `sudo systemctl start mysql`                     |

---

## Advanced Administration

### Logs & Error Analysis

* PHP logs: `/var/log/php_errors.log` or configured `error_log`
* MySQL logs: `/var/log/mysql/error.log` or `/var/log/mysqld.log`

**Commands:**

```bash
tail -f /var/log/mysql/error.log
tail -f /var/log/php_errors.log
```

### User Privileges & Security

```sql
-- Show users
SELECT user, host FROM mysql.user;

-- Remove unnecessary users
DROP USER 'test'@'localhost';

-- Apply privileges
FLUSH PRIVILEGES;
```

### Hosting Multiple Websites

* Using virtual hosts (Apache) or server blocks (Nginx):

```
/var/www/site1.com/
  index.php
/var/www/site2.com/
  index.php
```

* Apache virtual host example:

```apache
<VirtualHost *:80>
    ServerName site1.com
    DocumentRoot /var/www/site1.com
</VirtualHost>
```

* Nginx server block example:

```nginx
server {
    listen 80;
    server_name site1.com;
    root /var/www/site1.com;
}
```

### Performance Tuning

* Adjust PHP memory, max execution time (`php.ini`)
* Enable query caching in MySQL (`my.cnf`)
* Use indexes for large tables
* Monitor slow queries: `/var/log/mysql/mysql-slow.log`

---

## Networking & DNS

* PHP + MySQL server communicates over TCP/IP (default MySQL port 3306)
* Localhost connections: `127.0.0.1`
* Remote connections: Ensure firewall allows port 3306
* DNS maps domain names to IPs for virtual hosts
* Example: `ping site1.com` resolves to server IP

---

## Summary & Best Practices

* Always use strong passwords for MySQL users.
* Keep PHP & MySQL updated.
* Use separate users for each application for security.
* Regularly backup databases.
* Use error logs for troubleshooting.
* Avoid exposing MySQL port to the public unless required.
* Use version control for PHP applications.

---

## References

* [PHP Official Documentation](https://www.php.net/docs.php)
* [MySQL Official Documentation](https://dev.mysql.com/doc/)
* [MariaDB Documentation](https://mariadb.com/kb/en/)
* [Apache Virtual Hosts](https://httpd.apache.org/docs/current/vhosts/)
* [Nginx Server Blocks](https://www.nginx.com/resources/wiki/start/topics/examples/server_blocks/)

---
