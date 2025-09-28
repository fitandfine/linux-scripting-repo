

# 🐳 Docker Basics — Beginner to Advanced

Author: **Anup Chapain**
File: `docker_basics.md`
Purpose: Study notes & revision guide for Docker alongside `docker_helper.sh`.

---

## 📌 What is Docker?

* **Docker** is a tool that lets you package applications into **containers**.
* A **container** is like a lightweight virtual machine — it runs your app with everything it needs (dependencies, libraries, config).
* Containers are **portable**: the same image runs on any Linux machine with Docker installed.
* Unlike VMs, containers share the host OS kernel, making them **fast and efficient**.

---

## ⚙️ Key Concepts in Docker

### 1. **Images**

* Blueprint for containers.
* Built from a `Dockerfile`.
* Example: `nginx:latest` is an image.

Commands:

```bash
docker images           # List images
docker pull nginx       # Download an image from Docker Hub
docker rmi nginx        # Remove an image
```

---

### 2. **Containers**

* Running instances of images.
* Each container is isolated but can talk to others via networking.

Commands:

```bash
docker ps               # List running containers
docker ps -a            # List all containers (including stopped)
docker run hello-world  # Run a test container
docker run -d -p 8080:80 nginx  # Run nginx detached, expose port 8080
docker stop <id>        # Stop a container
docker rm <id>          # Remove a container
```

---

### 3. **Docker Hub**

* Public registry for Docker images.
* Default source when you `docker pull` something.

Example:

```bash
docker pull ubuntu:22.04
docker run -it ubuntu:22.04 bash
```

---

### 4. **Volumes**

* Way to persist data outside containers (since containers are ephemeral).
* Example: A database container needs storage that won’t disappear when restarted.

Commands:

```bash
docker volume create mydata
docker run -v mydata:/var/lib/mysql mysql
docker volume ls
docker volume rm mydata
```

---

### 5. **Networks**

* Containers can communicate through Docker networks.
* Useful for multi-container apps (e.g., WordPress + MySQL).

Commands:

```bash
docker network ls
docker network create mynet
docker run -d --network=mynet mysql
docker run -d --network=mynet wordpress
```

---

### 6. **Dockerfile**

* A recipe file for building images.

Example `Dockerfile`:

```dockerfile
FROM ubuntu:22.04
RUN apt update && apt install -y python3
CMD ["python3", "--version"]
```

Build and run:

```bash
docker build -t my-python .
docker run my-python
```

---

### 7. **Docker Compose**

* Tool for running multi-container applications using a single config file (`docker-compose.yml`).

Example `docker-compose.yml` for WordPress:

```yaml
version: "3"
services:
  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: wordpress
  wordpress:
    image: wordpress
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_PASSWORD: root
```

Run:

```bash
docker compose up -d
docker compose down
```

---

## 🔧 Docker Helper Script (`docker_helper.sh`)

This script makes common Docker tasks beginner-friendly:

* `--status` → Check if Docker is installed & running
* `--list-containers` → Show running containers
* `--list-images` → Show available images
* `--run-test` → Run hello-world or nginx
* `--stop` → Stop a container interactively
* `--remove` → Remove a container interactively
* `--cleanup` → Remove unused containers/images/cache

---

## 🚨 Troubleshooting Tips

1. **Docker not installed**

```bash
sudo apt install docker.io -y     # Debian/Ubuntu
sudo yum install docker -y        # CentOS/RHEL
```

2. **Permission denied when running docker**

```bash
sudo usermod -aG docker $USER
newgrp docker
```

3. **Docker service not running**

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

4. **Port already in use**

```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

5. **Clean up space**

```bash
docker system prune -a
```

---

## 🎯 Learning Path with Docker

1. Run `hello-world` container.
2. Run an `nginx` container → access via `http://localhost:8080`.
3. Learn volumes → mount a folder from host.
4. Connect two containers via a custom network.
5. Write your first `Dockerfile`.
6. Use Docker Compose to deploy WordPress + MySQL.
7. Practice `docker_helper.sh` for everyday management.

---

## 📚 Revision Cheatsheet

```bash
docker ps                # Running containers
docker ps -a             # All containers
docker images            # Images
docker pull <image>      # Download image
docker run <image>       # Run container
docker exec -it <id> sh  # Open shell inside container
docker stop <id>         # Stop
docker rm <id>           # Remove
docker rmi <id>          # Remove image
docker logs <id>         # View logs
docker system prune -a   # Clean up everything
```

---

