
# 📘 The Complete Nginx Server Guide

A **self-contained guide** to learning, configuring, and troubleshooting Nginx for web hosting and advanced Linux administration.

---

## 📌 Table of Contents

1. [What is Nginx?](#-what-is-nginx)
2. [Why Use Nginx?](#-why-use-nginx)
3. [How Nginx Works (Theory)](#-how-nginx-works-theory)
4. [Installing Nginx](#-installing-nginx)
5. [Understanding Nginx File Structure](#-understanding-nginx-file-structure)
6. [Managing the Nginx Service](#-managing-the-nginx-service)
7. [Nginx Configuration Explained](#-nginx-configuration-explained)
8. [Hosting a Single Website](#-hosting-a-single-website)
9. [Hosting Multiple Websites (Virtual Hosts)](#-hosting-multiple-websites-virtual-hosts)
10. [How Nginx Communicates with DNS](#-how-nginx-communicates-with-dns)
11. [SSL/TLS and HTTPS Setup](#-ssltls-and-https-setup)
12. [Nginx as a Reverse Proxy](#-nginx-as-a-reverse-proxy)
13. [Load Balancing Theory & Practice](#-load-balancing-theory--practice)
14. [Firewall, Security & Hardening](#-firewall-security--hardening)
15. [Logs, Monitoring & Debugging](#-logs-monitoring--debugging)
16. [Common Errors & Solutions](#-common-errors--solutions)
17. [Advanced Linux System Administration for Nginx](#-advanced-linux-system-administration-for-nginx)
18. [Best Practices](#-best-practices)
19. [Troubleshooting Decision Tree](#-troubleshooting-decision-tree)

---

## 📌 What is Nginx?

* **Nginx (Engine-X)** is an **open-source, high-performance web server** and **reverse proxy server**.
* It was created by **Igor Sysoev in 2004** to solve the **C10k problem** (serving 10,000+ concurrent clients).
* Unlike older servers like **Apache** (process/thread-based), Nginx uses an **event-driven, asynchronous architecture** → more efficient and scalable.

---

## 📌 Why Use Nginx?

* **High Performance**: Handles 10k+ concurrent connections with low memory usage.
* **Versatile**: Can act as:

  * Web server (static & dynamic content).
  * Reverse proxy (forwarding requests to backend).
  * Load balancer (distributing requests across servers).
  * SSL/TLS terminator.
* **Widely used**: Powers companies like Netflix, Airbnb, Dropbox, and WordPress.

---

## 📌 How Nginx Works (Theory)

* **Master Process**:

  * Reads configs.
  * Spawns worker processes.
* **Worker Processes**:

  * Handle client connections using **non-blocking I/O**.
* **Event-driven Model**:

  * Instead of creating a new thread per request, it reuses workers to handle thousands of requests efficiently.

**Request flow:**

1. User enters `example.com`.
2. DNS resolves → IP address of server.
3. Browser connects to server on port 80/443.
4. Nginx receives request → matches **server_name** in config.
5. Serves static content or proxies request to backend (PHP, Node.js, Python).

---

## 📌 Installing Nginx

### On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install nginx -y
```

### On CentOS/RHEL:

```bash
sudo yum install epel-release -y
sudo yum install nginx -y
```

### Verify installation:

```bash
nginx -v
```

Check if running:

```bash
systemctl status nginx
```

---

## 📌 Understanding Nginx File Structure

| Path                          | Purpose                    |
| ----------------------------- | -------------------------- |
| `/etc/nginx/nginx.conf`       | Main config file           |
| `/etc/nginx/sites-available/` | Virtual host configs       |
| `/etc/nginx/sites-enabled/`   | Symlinks to active configs |
| `/var/www/html/`              | Default web root           |
| `/var/log/nginx/access.log`   | Access log                 |
| `/var/log/nginx/error.log`    | Error log                  |

---

## 📌 Managing the Nginx Service

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx   # reload configs without downtime
```

Check listening ports:

```bash
ss -tulpn | grep nginx
```

---

## 📌 Nginx Configuration Explained

### Structure of a `server` block:

```nginx
server {
    listen 80;                        # Port to listen on
    server_name example.com www.example.com;   # Domain names
    root /var/www/example.com/html;   # Web root
    index index.html index.htm;       # Default files

    location / {
        try_files $uri $uri/ =404;    # File handling
    }
}
```

* **listen** → defines which port/protocol (HTTP=80, HTTPS=443).
* **server_name** → tells Nginx which domain the config applies to.
* **root** → location of files.
* **location** → define how requests are handled.

---

## 📌 Hosting a Single Website

1. Create web root:

```bash
sudo mkdir -p /var/www/example.com/html
echo "<h1>Hello from Example.com</h1>" | sudo tee /var/www/example.com/html/index.html
```

2. Create config:

```bash
sudo nano /etc/nginx/sites-available/example.com
```

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com/html;
    index index.html;
}
```

3. Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

## 📌 Hosting Multiple Websites (Virtual Hosts)

Example: **example.com** + **test.com** on the same server.

```nginx
# example.com
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com/html;
}

# test.com
server {
    listen 80;
    server_name test.com www.test.com;
    root /var/www/test.com/html;
}
```

Now both domains resolve based on `server_name`.

---

## 📌 How Nginx Communicates with DNS

* **DNS role**: Maps domain → server’s public IP.
* Example DNS record:

```
example.com. IN A 203.0.113.10
```

* Flow:

  1. User types `example.com`.
  2. DNS resolves to `203.0.113.10`.
  3. Browser → server:80/443.
  4. Nginx matches `server_name`.

If DNS is wrong, **site won’t load** → fix DNS records.

---

## 📌 SSL/TLS and HTTPS Setup

### Install Certbot:

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### Get SSL certificate:

```bash
sudo certbot --nginx -d example.com -d www.example.com
```

Test auto-renew:

```bash
sudo certbot renew --dry-run
```

---

## 📌 Nginx as a Reverse Proxy

Example: Proxy `/api` to backend `http://127.0.0.1:5000`.

```nginx
server {
    listen 80;
    server_name example.com;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📌 Load Balancing Theory & Practice

**Theory**: Distribute client requests across multiple backend servers.

* Methods:

  * Round robin (default).
  * Least connections.
  * IP hash (stickiness).

Example:

```nginx
upstream backend_servers {
    server 127.0.0.1:5000;
    server 127.0.0.1:5001;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend_servers;
    }
}
```

---

## 📌 Firewall, Security & Hardening

Allow Nginx traffic:

```bash
sudo ufw allow 'Nginx Full'
```

Hide version:

```nginx
server_tokens off;
```

Limit request rate:

```nginx
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
```

---

## 📌 Logs, Monitoring & Debugging

* Access logs:

```bash
tail -f /var/log/nginx/access.log
```

* Error logs:

```bash
tail -f /var/log/nginx/error.log
```

Real-time monitoring:

```bash
sudo apt install goaccess -y
goaccess /var/log/nginx/access.log --log-format=COMBINED
```

---

## 📌 Common Errors & Solutions

| Error                  | Cause                                   | Fix                          |
| ---------------------- | --------------------------------------- | ---------------------------- |
| `502 Bad Gateway`      | Backend app crashed or wrong proxy_pass | Restart backend, check ports |
| `403 Forbidden`        | Wrong permissions                       | `chmod -R 755 /var/www/`     |
| `404 Not Found`        | Wrong root path                         | Verify `root` in config      |
| `nginx: [emerg]`       | Config error                            | Run `nginx -t`               |
| `SSL handshake failed` | Expired or misconfigured cert           | `certbot renew`              |

---

## 📌 Advanced Linux System Administration for Nginx

* Check processes:

```bash
ps aux | grep nginx
```

* Graceful reload:

```bash
sudo nginx -s reload
```

* Limit simultaneous connections:

```nginx
limit_conn_zone $binary_remote_addr zone=perip:10m;
limit_conn perip 10;
```

* Disk usage (logs can fill space):

```bash
df -h
```

---

## 📌 Best Practices

* Always `nginx -t` before reload.
* Use HTTPS everywhere.
* Isolate websites with separate configs.
* Automate SSL renewal.
* Rotate logs to save disk space.

---

## 📌 Troubleshooting Decision Tree

1. **Site not loading?**

   * Check if Nginx is running: `systemctl status nginx`.
   * Check DNS with `dig example.com`.
   * Verify firewall rules.

2. **Getting 502 Bad Gateway?**

   * Backend crashed? Restart it.
   * Wrong proxy_pass? Fix in config.

3. **SSL errors?**

   * Check expiration: `openssl s_client -connect example.com:443`.
   * Renew certs: `certbot renew`.

4. **High CPU or memory usage?**

   * Use `htop` to see workers.
   * Check access logs for DDoS.
   * Apply rate limiting.

---
