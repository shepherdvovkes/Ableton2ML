#!/bin/bash

# Ableton2ML Google Cloud Deployment Script
# Deploys Google Magenta server with CUDA GPU support

set -e

# Configuration
PROJECT_ID="your-project-id"
ZONE="us-central1-a"
INSTANCE_NAME="ableton2ml-server"
MACHINE_TYPE="n1-standard-4"
GPU_TYPE="nvidia-tesla-t4"
GPU_COUNT="1"
DISK_SIZE="50GB"
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Ableton2ML Google Cloud Deployment${NC}"
echo "=================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if project is set
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-project-id" ]; then
    echo -e "${RED}Error: Please set PROJECT_ID in the script${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting up Google Cloud project...${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Create startup script
echo -e "${YELLOW}Creating startup script...${NC}"
cat > startup-script.sh << 'EOF'
#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install Python and dependencies
apt-get install -y python3 python3-pip python3-venv git curl wget

# Install CUDA and cuDNN
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
apt-get update
apt-get install -y cuda-toolkit-11-8

# Set CUDA environment variables
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> /etc/profile
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> /etc/profile

# Create application directory
mkdir -p /opt/ableton2ml
cd /opt/ableton2ml

# Clone repository (replace with your actual repo)
git clone https://github.com/your-repo/ableton2ml.git .

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Download Google Magenta models
python -c "
import magenta
from magenta.models.music_vae import configs
from magenta.models.music_transformer import music_transformer
print('Downloading Magenta models...')
"

# Create systemd service
cat > /etc/systemd/system/ableton2ml.service << 'SERVICEEOF'
[Unit]
Description=Ableton2ML Magenta Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ableton2ml
Environment=PATH=/opt/ableton2ml/venv/bin
ExecStart=/opt/ableton2ml/venv/bin/python server/magenta_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Enable and start service
systemctl enable ableton2ml.service
systemctl start ableton2ml.service

# Create firewall rule
gcloud compute firewall-rules create ableton2ml-http \
    --allow tcp:5000 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic to Ableton2ML server"

echo "Ableton2ML server deployment completed!"
EOF

# Create instance with GPU
echo -e "${YELLOW}Creating VM instance with GPU...${NC}"
gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --maintenance-policy=TERMINATE \
    --accelerator="type=$GPU_TYPE,count=$GPU_COUNT" \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$DISK_SIZE \
    --boot-disk-type=pd-ssd \
    --metadata-from-file startup-script=startup-script.sh \
    --scopes=cloud-platform \
    --tags=http-server,https-server

# Wait for instance to be ready
echo -e "${YELLOW}Waiting for instance to be ready...${NC}"
sleep 30

# Get external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "=================================="
echo -e "${GREEN}Server IP: ${EXTERNAL_IP}${NC}"
echo -e "${GREEN}API Endpoint: http://${EXTERNAL_IP}:5000${NC}"
echo -e "${GREEN}Status: http://${EXTERNAL_IP}:5000/api/status${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait 5-10 minutes for startup script to complete"
echo "2. Test the API endpoint"
echo "3. Update your Ableton2ML plugin with the server IP"
echo ""
echo -e "${YELLOW}To check server status:${NC}"
echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo systemctl status ableton2ml'"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command='sudo journalctl -u ableton2ml -f'"

# Clean up startup script
rm -f startup-script.sh
