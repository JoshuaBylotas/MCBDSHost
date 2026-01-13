#!/bin/bash

################################################################################
# MCBDSHost Deployment Update Script
# 
# This script pulls the latest code from GitHub and updates the running
# Docker containers with zero-downtime deployment strategy.
#
# Usage: ./update-deployment.sh [--force] [--no-backup]
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_FILE="$SCRIPT_DIR/update-$(date +%Y%m%d-%H%M%S).log"

# Options
FORCE_UPDATE=false
SKIP_BACKUP=false

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

confirm() {
    if [ "$FORCE_UPDATE" = true ]; then
        return 0
    fi
    
    read -p "$1 (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a Git repository. Please run this script from the MCBDSHost directory."
        exit 1
    fi
    
    log "All prerequisites met ?"
}

backup_volumes() {
    if [ "$SKIP_BACKUP" = true ]; then
        warning "Skipping backup as requested"
        return
    fi
    
    log "Creating backup of Docker volumes..."
    
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Backup worlds
    if docker volume ls | grep -q mcbds-worlds; then
        info "Backing up world data..."
        docker run --rm \
            -v mcbds-worlds:/data \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf "/backup/worlds-backup-$TIMESTAMP.tar.gz" /data
        log "World data backed up to: $BACKUP_DIR/worlds-backup-$TIMESTAMP.tar.gz"
    fi
    
    # Backup config
    if docker volume ls | grep -q mcbds-config; then
        info "Backing up configuration..."
        docker run --rm \
            -v mcbds-config:/data \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf "/backup/config-backup-$TIMESTAMP.tar.gz" /data
        log "Configuration backed up to: $BACKUP_DIR/config-backup-$TIMESTAMP.tar.gz"
    fi
    
    log "Backup completed ?"
}

check_for_updates() {
    log "Checking for updates..."
    
    # Fetch latest from remote
    git fetch origin master
    
    # Check if there are updates
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/master)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log "Already up to date. No updates needed."
        if ! confirm "Do you want to rebuild anyway?"; then
            exit 0
        fi
    else
        info "Updates available"
        git log --oneline HEAD..origin/master
    fi
}

pull_latest_code() {
    log "Pulling latest code from GitHub..."
    
    # Check for local changes
    if ! git diff-index --quiet HEAD --; then
        warning "Local changes detected"
        if confirm "Do you want to stash local changes?"; then
            git stash
            log "Local changes stashed"
        else
            error "Cannot pull with local changes. Aborting."
            exit 1
        fi
    fi
    
    # Pull latest code
    if git pull origin master; then
        log "Code updated successfully ?"
    else
        error "Failed to pull latest code"
        exit 1
    fi
}

stop_containers() {
    log "Stopping running containers..."
    
    if docker compose ps --services --filter "status=running" | grep -q .; then
        docker compose down
        log "Containers stopped ?"
    else
        info "No running containers found"
    fi
}

build_images() {
    log "Building Docker images..."
    
    if docker compose build --no-cache; then
        log "Images built successfully ?"
    else
        error "Failed to build Docker images"
        exit 1
    fi
}

start_containers() {
    log "Starting containers..."
    
    if docker compose up -d; then
        log "Containers started ?"
    else
        error "Failed to start containers"
        exit 1
    fi
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Wait for containers to be healthy
    sleep 5
    
    # Check if containers are running
    if docker compose ps --services --filter "status=running" | grep -q .; then
        log "Containers are running ?"
    else
        error "Containers failed to start"
        docker compose logs
        exit 1
    fi
    
    # Check API health endpoint
    info "Checking API health..."
    for i in {1..30}; do
        if curl -f http://localhost:8080/health > /dev/null 2>&1; then
            log "API health check passed ?"
            break
        else
            if [ $i -eq 30 ]; then
                warning "API health check failed after 30 attempts"
            else
                sleep 2
            fi
        fi
    done
}

show_status() {
    log "Deployment Status:"
    docker compose ps
    
    echo ""
    log "Recent Logs:"
    docker compose logs --tail=20
}

cleanup_old_backups() {
    log "Cleaning up old backups (keeping last 5)..."
    
    if [ -d "$BACKUP_DIR" ]; then
        # Keep only the 5 most recent backups
        ls -t "$BACKUP_DIR"/worlds-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
        ls -t "$BACKUP_DIR"/config-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
        log "Old backups cleaned up ?"
    fi
}

################################################################################
# Parse Arguments
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --no-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force        Skip confirmation prompts"
            echo "  --no-backup    Skip backup creation (not recommended)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Main Execution
################################################################################

log "========================================="
log "MCBDSHost Deployment Update Started"
log "========================================="

# Run update steps
check_prerequisites
check_for_updates

if ! [ "$FORCE_UPDATE" = true ]; then
    echo ""
    warning "This will update your deployment and may cause brief downtime."
    if ! confirm "Do you want to continue?"; then
        log "Update cancelled by user"
        exit 0
    fi
fi

backup_volumes
pull_latest_code
stop_containers
build_images
start_containers
verify_deployment
cleanup_old_backups
show_status

log "========================================="
log "Update Completed Successfully! ?"
log "========================================="
log "Log file: $LOG_FILE"

exit 0
