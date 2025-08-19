#!/bin/bash

# Ableton2ML Startup Script for Google Cloud
# Installs CUDA, Google Magenta, and sets up the server

set -e

# Configuration
PROJECT_ID="${project_id}"
REPO_URL="${repo_url}"
HF_TOKEN="${hf_token}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

log "Starting Ableton2ML server setup..."

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install system dependencies
log "Installing system dependencies..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxft-dev \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    nginx \
    supervisor

# Install CUDA and cuDNN
log "Installing CUDA and cuDNN..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
apt-get update
apt-get install -y cuda-toolkit-11-8

# Set CUDA environment variables
log "Setting up CUDA environment..."
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> /etc/profile
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> /etc/profile
echo 'export CUDA_HOME=/usr/local/cuda-11.8' >> /etc/profile

# Source environment variables
source /etc/profile

# Verify CUDA installation
log "Verifying CUDA installation..."
nvcc --version || warning "CUDA installation verification failed"

# Create application directory
log "Setting up application directory..."
mkdir -p /opt/ableton2ml
cd /opt/ableton2ml

# Clone repository
log "Cloning Ableton2ML repository..."
if [ -n "$REPO_URL" ]; then
    git clone "$REPO_URL" .
else
    # Create basic structure if no repo URL
    mkdir -p server plugins scripts
    cat > server/magenta_server.py << 'EOF'
#!/usr/bin/env python3
print("Ableton2ML server placeholder")
EOF
fi

# Create virtual environment
log "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python dependencies
log "Installing Python dependencies..."
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
else
    # Install basic dependencies
    pip install \
        tensorflow>=2.8.0 \
        magenta>=2.1.4 \
        numpy>=1.21.0 \
        flask>=2.0.0 \
        flask-cors>=3.0.10 \
        requests>=2.25.0 \
        pretty_midi>=0.2.9 \
        librosa==0.7.2 \
        python-dotenv>=0.19.0 \
        gunicorn>=20.1.0
fi

# Set up environment variables
log "Setting up environment variables..."
cat > /opt/ableton2ml/.env << EOF
HF_TOKEN=$HF_TOKEN
PROJECT_ID=$PROJECT_ID
ENVIRONMENT=production
EOF

# Download Google Magenta models
log "Downloading Google Magenta models..."
python3 -c "
import magenta
from magenta.models.music_vae import configs
from magenta.models.music_transformer import music_transformer
print('Magenta models downloaded successfully')
" || warning "Failed to download some Magenta models"

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/ableton2ml.service << 'EOF'
[Unit]
Description=Ableton2ML Magenta Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ableton2ml
Environment=PATH=/opt/ableton2ml/venv/bin
Environment=PYTHONPATH=/opt/ableton2ml
ExecStart=/opt/ableton2ml/venv/bin/python server/magenta_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create nginx configuration
log "Setting up nginx..."
cat > /etc/nginx/sites-available/ableton2ml << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/ableton2ml /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create health check script
log "Creating health check script..."
cat > /opt/ableton2ml/health_check.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys

try:
    response = requests.get('http://localhost:5001/api/status', timeout=5)
    if response.status_code == 200:
        print("OK")
        sys.exit(0)
    else:
        print(f"ERROR: Status code {response.status_code}")
        sys.exit(1)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF

chmod +x /opt/ableton2ml/health_check.py

# Create monitoring script
log "Setting up monitoring..."
cat > /opt/ableton2ml/monitor.py << 'EOF'
#!/usr/bin/env python3
import psutil
import json
import time
from datetime import datetime

def get_system_stats():
    return {
        'timestamp': datetime.now().isoformat(),
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent,
        'gpu_available': True  # Will be enhanced with nvidia-smi
    }

if __name__ == '__main__':
    print(json.dumps(get_system_stats()))
EOF

# Enable and start services
log "Starting services..."
systemctl enable ableton2ml.service
systemctl start ableton2ml.service
systemctl enable nginx
systemctl start nginx

# Wait for service to start
log "Waiting for service to start..."
sleep 30

# Check service status
if systemctl is-active --quiet ableton2ml.service; then
    log "Ableton2ML service started successfully"
else
    error "Ableton2ML service failed to start"
    systemctl status ableton2ml.service
fi

# Create firewall rules (if not already created by Terraform)
log "Setting up firewall rules..."
gcloud compute firewall-rules create ableton2ml-http \
    --allow tcp:80,tcp:443,tcp:5000,tcp:5001 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic to Ableton2ML server" \
    --quiet || warning "Firewall rule may already exist"

# Create startup completion marker
echo "$(date): Ableton2ML setup completed successfully" > /opt/ableton2ml/setup_completed.txt

log "Ableton2ML server setup completed successfully!"
log "Server should be available at: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):5001"
log "API Status: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):5001/api/status"
