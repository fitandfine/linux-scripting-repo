#!/usr/bin/env bash
# docker_helper.sh
#
# Author: Anup Chapain
#
# A beginner-friendly Docker management helper script for Linux.
#
# Features:
#   * Check if Docker is installed (and guide to install if missing)
#   * List running containers
#   * List available Docker images
#   * Run a simple test container (nginx or hello-world)
#   * Stop or remove containers interactively
#   * Clean up unused Docker resources
#   * Beginner-friendly with clear help instructions
#
# Usage:
#   ./docker_helper.sh --help
#   ./docker_helper.sh --status
#   ./docker_helper.sh --list-containers
#   ./docker_helper.sh --list-images
#   ./docker_helper.sh --run-test
#   ./docker_helper.sh --stop
#   ./docker_helper.sh --remove
#   ./docker_helper.sh --cleanup
#

# ------------------------------------------------------------
# Function: show_help
# Display usage instructions in a friendly way
# ------------------------------------------------------------
show_help() {
    cat <<EOF
Docker Helper Script
--------------------

Usage:
  ./docker_helper.sh [OPTION]

Options:
  --status           Check if Docker is installed and running
  --list-containers  List running Docker containers
  --list-images      List Docker images available locally
  --run-test         Run a test container (nginx or hello-world)
  --stop             Stop a running container (interactive prompt)
  --remove           Remove a container (interactive prompt)
  --cleanup          Remove unused images, containers, and cache
  -h | --help        Show this help message

Examples:
  ./docker_helper.sh --status
  ./docker_helper.sh --run-test
EOF
}

# ------------------------------------------------------------
# Function: check_docker
# Check if Docker is installed and running
# ------------------------------------------------------------
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed."
        echo "👉 To install on Ubuntu/Debian: sudo apt install docker.io -y"
        exit 1
    else
        echo "✔ Docker is installed: $(docker --version)"
    fi

    # Check if Docker service is running
    if systemctl is-active --quiet docker; then
        echo "✔ Docker service is running."
    else
        echo "❌ Docker service is not running."
        echo "👉 Start it with: sudo systemctl start docker"
    fi
}

# ------------------------------------------------------------
# Function: list_containers
# Show currently running containers
# ------------------------------------------------------------
list_containers() {
    echo "📦 Running containers:"
    docker ps
}

# ------------------------------------------------------------
# Function: list_images
# Show locally available Docker images
# ------------------------------------------------------------
list_images() {
    echo "🖼 Available Docker images:"
    docker images
}

# ------------------------------------------------------------
# Function: run_test_container
# Run a test container (nginx web server or hello-world)
# ------------------------------------------------------------
run_test_container() {
    echo "Which test container do you want to run?"
    echo "1) hello-world (very small, just prints a test message)"
    echo "2) nginx (web server, accessible in browser at http://localhost:8080)"
    read -p "Enter choice [1-2]: " choice

    case $choice in
        1)
            echo "➡ Running hello-world container..."
            docker run hello-world
            ;;
        2)
            echo "➡ Running nginx container on port 8080..."
            docker run -d -p 8080:80 --name test-nginx nginx
            echo "✔ Nginx is running. Open http://localhost:8080 in your browser."
            ;;
        *)
            echo "❌ Invalid choice."
            ;;
    esac
}

# ------------------------------------------------------------
# Function: stop_container
# Stop a container interactively
# ------------------------------------------------------------
stop_container() {
    echo "📦 Running containers:"
    docker ps
    read -p "Enter the container ID or name to stop: " cid
    docker stop "$cid"
    echo "✔ Container stopped."
}

# ------------------------------------------------------------
# Function: remove_container
# Remove a container interactively
# ------------------------------------------------------------
remove_container() {
    echo "📦 All containers (running and stopped):"
    docker ps -a
    read -p "Enter the container ID or name to remove: " cid
    docker rm "$cid"
    echo "✔ Container removed."
}

# ------------------------------------------------------------
# Function: cleanup_docker
# Remove unused Docker resources
# ------------------------------------------------------------
cleanup_docker() {
    echo "🧹 Cleaning up unused Docker resources..."
    docker system prune -f
    echo "✔ Cleanup complete."
}

# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    -h | --help)
        show_help
        ;;
    --status)
        check_docker
        ;;
    --list-containers)
        list_containers
        ;;
    --list-images)
        list_images
        ;;
    --run-test)
        run_test_container
        ;;
    --stop)
        stop_container
        ;;
    --remove)
        remove_container
        ;;
    --cleanup)
        cleanup_docker
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo "👉 Use ./docker_helper.sh --help to see available options."
        exit 1
        ;;
esac
