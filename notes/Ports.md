
# Complete Guide to Computer Ports

## Table of Contents
1. [Introduction to Ports](#introduction-to-ports)
2. [Types of Ports](#types-of-ports)
3. [Port Numbers and Ranges](#port-numbers-and-ranges)
4. [TCP vs UDP Ports](#tcp-vs-udp-ports)
5. [Common Ports and Services](#common-ports-and-services)
6. [How Ports Work](#how-ports-work)
7. [Port Scanning and Security](#port-scanning-and-security)
8. [Checking Open Ports on Linux](#checking-open-ports-on-linux)
9. [Finding Which Service Uses a Port](#finding-which-service-uses-a-port)
10. [Freeing Ports / Killing Processes](#freeing-ports--killing-processes)
11. [Port Forwarding](#port-forwarding)
12. [Multi-site Hosting Using Ports](#multi-site-hosting-using-ports)
13. [Troubleshooting Port Issues](#troubleshooting-port-issues)
14. [Best Practices](#best-practices)
15. [References](#references)

---

## Introduction to Ports
- A **port** is a logical endpoint in a computer network used to differentiate multiple services on the same IP address.
- Think of a port like a **door** in a building (IP = building address, port = door number).
- Every network service (like HTTP, SSH, FTP) listens on a specific port.
- Without ports, the computer wouldn’t know which service should handle incoming data.

---

## Types of Ports
1. **Physical Ports**
   - USB, HDMI, Ethernet — actual hardware connectors.
2. **Logical (Network) Ports**
   - Used by software applications.
   - Range: 0–65535 (16-bit numbers).
   - Only logical ports are relevant for networking and DevOps.

---

## Port Numbers and Ranges
| Range                 | Description |
|-----------------------|-------------|
| 0–1023                | Well-known ports (system or root required to bind) |
| 1024–49151            | Registered ports (can be used by user applications) |
| 49152–65535           | Dynamic / ephemeral ports (temporary for client connections) |

**Example:**  
- HTTP: 80 (well-known)  
- HTTPS: 443 (well-known)  
- SSH: 22 (well-known)  
- Random browser port: 51034 (ephemeral)

---

## TCP vs UDP Ports
### TCP (Transmission Control Protocol)
- Connection-oriented.
- Reliable: guarantees delivery and order.
- Used by HTTP, HTTPS, FTP, SSH.

### UDP (User Datagram Protocol)
- Connectionless.
- Fast but unreliable: no guarantee of delivery or order.
- Used by DNS, DHCP, VoIP, streaming.

---

## Common Ports and Services
| Port | Protocol | Service      |
|------|----------|--------------|
| 20   | TCP      | FTP Data     |
| 21   | TCP      | FTP Control  |
| 22   | TCP      | SSH          |
| 25   | TCP      | SMTP         |
| 53   | TCP/UDP  | DNS          |
| 67   | UDP      | DHCP Server  |
| 80   | TCP      | HTTP         |
| 443  | TCP      | HTTPS        |
| 3306 | TCP      | MySQL        |
| 5432 | TCP      | PostgreSQL   |
| 6379 | TCP      | Redis        |
| 27017| TCP      | MongoDB      |

---

## How Ports Work
1. **Listening**: Server binds a port to wait for incoming connections.
2. **Connecting**: Client connects to IP:Port to access the service.
3. **Data Flow**: Data packets are directed to the right port.
4. **Closing**: Connection is terminated; ephemeral port is freed.

---

## Port Scanning and Security
- **Port scanning** checks which ports are open.
- Tools: `nmap`, `netstat`, `ss`.
- Security risk: exposed ports can be exploited.
- Best practices:
  - Close unused ports.
  - Use firewalls.
  - Run services with least privileges.

---

## Checking Open Ports on Linux
### Using `ss` (preferred)
```bash
ss -tulpn
````

* `-t` TCP, `-u` UDP, `-l` listening, `-p` show PID/program name, `-n` numeric

### Using `netstat` (older)

```bash
sudo netstat -tulpn
```

### Using `lsof`

```bash
sudo lsof -i -P -n
```

---

## Finding Which Service Uses a Port

* `lsof -i :<port>` → shows process, PID, user
* `fuser <port>/tcp` → shows PID
* Example:

```bash
sudo lsof -i :80
# Output: apache2 12345 root TCP *:80
```

---

## Freeing Ports / Killing Processes

**Important:** Avoid killing critical system services (like `sshd`).

1. Find the PID:

```bash
sudo lsof -i :8080
```

2. Kill the process (if safe):

```bash
kill -9 <PID>
```

3. If systemd service (e.g., Apache):

```bash
sudo systemctl stop apache2
sudo systemctl disable apache2   # prevent auto-restart
```

---

## Port Forwarding

* Ports can be forwarded from one IP/port to another.
* Used in routers or NAT to allow external access to internal services.

```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80
```

---

## Multi-site Hosting Using Ports

* Multiple services/websites can run on the same server using:

  1. Different ports (e.g., 80, 8080, 8000)
  2. Reverse proxy (e.g., Nginx) with **virtual hosts**:

```nginx
server {
    listen 80;
    server_name site1.example.com;
    root /var/www/site1;
}
server {
    listen 80;
    server_name site2.example.com;
    root /var/www/site2;
}
```

* DNS points domain to server IP; Nginx directs traffic to correct site.

---

## Troubleshooting Port Issues

1. Port already in use → use `lsof` / `ss` to find process.
2. Cannot bind to port <1024 → need root privileges.
3. Service auto-restarts after kill → likely systemd-managed.
4. Firewall blocks port → check `ufw` or `firewalld`.

---

## Best Practices

* Only open necessary ports.
* Use firewalls and security groups.
* Use systemd to manage critical services.
* Monitor ports regularly using scripts.
* Avoid using privileged ports for user apps unless necessary.

---

## References

* [Linux man pages: ss](https://man7.org/linux/man-pages/man8/ss.8.html)
* [IANA Service Name and Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)
* [Nmap Security Scanner](https://nmap.org/)
* [Linux lsof Command](https://linux.die.net/man/8/lsof)


