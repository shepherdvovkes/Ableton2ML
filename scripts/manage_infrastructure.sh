#!/bin/bash

# Ableton2ML Infrastructure Management Script
# Manages Google Cloud infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"

# Functions
show_help() {
    echo -e "${GREEN}Ableton2ML Infrastructure Management${NC}"
    echo "============================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Deploy infrastructure"
    echo "  destroy    - Destroy infrastructure"
    echo "  status     - Show infrastructure status"
    echo "  logs       - Show server logs"
    echo "  ssh        - SSH to server"
    echo "  restart    - Restart server"
    echo "  monitor    - Show resource monitoring"
    echo "  backup     - Create backup"
    echo "  update     - Update server"
    echo "  help       - Show this help"
    echo ""
}

check_requirements() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform is not installed${NC}"
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI is not installed${NC}"
        exit 1
    fi
    
    if [ ! -f "$TFVARS_FILE" ]; then
        echo -e "${RED}Error: terraform.tfvars not found${NC}"
        echo "Please run: cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
        exit 1
    fi
}

get_project_info() {
    PROJECT_ID=$(grep '^project_id' "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
    REGION=$(grep '^region' "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
    ZONE=$(grep '^zone' "$TFVARS_FILE" | cut -d'=' -f2 | tr -d ' "')
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-google-cloud-project-id" ]; then
        echo -e "${RED}Error: Please set project_id in $TFVARS_FILE${NC}"
        exit 1
    fi
}

deploy_infrastructure() {
    echo -e "${YELLOW}Deploying infrastructure...${NC}"
    cd "$TERRAFORM_DIR"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Plan and apply
    terraform plan -var-file="terraform.tfvars" -out="terraform.tfplan"
    
    echo -e "${YELLOW}Do you want to apply this plan? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply "terraform.tfplan"
        rm -f terraform.tfplan
        
        # Show outputs
        echo -e "${GREEN}Deployment completed!${NC}"
        show_outputs
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
        rm -f terraform.tfplan
    fi
}

destroy_infrastructure() {
    echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
    echo -e "${YELLOW}Are you sure? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cd "$TERRAFORM_DIR"
        terraform destroy -var-file="terraform.tfvars" -auto-approve
        echo -e "${GREEN}Infrastructure destroyed${NC}"
    else
        echo -e "${YELLOW}Destruction cancelled${NC}"
    fi
}

show_status() {
    echo -e "${BLUE}Infrastructure Status:${NC}"
    cd "$TERRAFORM_DIR"
    
    if [ -f "terraform.tfstate" ]; then
        echo -e "${GREEN}Infrastructure exists${NC}"
        
        # Get server IP
        SERVER_IP=$(terraform output -raw gpu_server_external_ip 2>/dev/null || echo "N/A")
        if [ "$SERVER_IP" != "N/A" ]; then
            echo -e "Server IP: ${SERVER_IP}"
            
            # Check API status
            echo -e "${YELLOW}Checking API status...${NC}"
            if curl -s "http://$SERVER_IP:5001/api/status" > /dev/null; then
                echo -e "${GREEN}API is running${NC}"
            else
                echo -e "${RED}API is not responding${NC}"
            fi
        fi
        
        # Show terraform outputs
        echo ""
        echo -e "${BLUE}Terraform Outputs:${NC}"
        terraform output
    else
        echo -e "${RED}No infrastructure found${NC}"
    fi
}

show_logs() {
    echo -e "${YELLOW}Showing server logs...${NC}"
    cd "$TERRAFORM_DIR"
    
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    echo -e "${BLUE}Recent logs:${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo journalctl -u ableton2ml -n 50 --no-pager"
    
    echo -e "${BLUE}Follow logs (Ctrl+C to stop):${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo journalctl -u ableton2ml -f"
}

ssh_to_server() {
    echo -e "${YELLOW}Connecting to server...${NC}"
    cd "$TERRAFORM_DIR"
    
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE"
}

restart_server() {
    echo -e "${YELLOW}Restarting server...${NC}"
    cd "$TERRAFORM_DIR"
    
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo systemctl restart ableton2ml"
    echo -e "${GREEN}Server restarted${NC}"
}

show_monitoring() {
    echo -e "${YELLOW}Showing resource monitoring...${NC}"
    cd "$TERRAFORM_DIR"
    
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    echo -e "${BLUE}GPU Status:${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="nvidia-smi" 2>/dev/null || echo "GPU not available"
    
    echo -e "${BLUE}System Resources:${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="top -bn1 | head -20"
    
    echo -e "${BLUE}Disk Usage:${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="df -h"
    
    echo -e "${BLUE}Memory Usage:${NC}"
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="free -h"
}

create_backup() {
    echo -e "${YELLOW}Creating backup...${NC}"
    cd "$TERRAFORM_DIR"
    
    BACKUP_DIR="/tmp/ableton2ml-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup terraform state
    cp terraform.tfstate "$BACKUP_DIR/"
    cp terraform.tfvars "$BACKUP_DIR/"
    
    # Backup server data
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo tar -czf /tmp/ableton2ml-data.tar.gz /opt/ableton2ml"
    gcloud compute scp "$SERVER_NAME:/tmp/ableton2ml-data.tar.gz" "$BACKUP_DIR/" --zone="$ZONE"
    
    echo -e "${GREEN}Backup created: $BACKUP_DIR${NC}"
}

update_server() {
    echo -e "${YELLOW}Updating server...${NC}"
    cd "$TERRAFORM_DIR"
    
    SERVER_NAME=$(terraform output -raw gpu_instance_name 2>/dev/null || echo "ableton2ml-magenta-gpu")
    
    # Update system packages
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo apt-get update && sudo apt-get upgrade -y"
    
    # Update application
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="cd /opt/ableton2ml && git pull && source venv/bin/activate && pip install -r requirements.txt"
    
    # Restart service
    gcloud compute ssh "$SERVER_NAME" --zone="$ZONE" --command="sudo systemctl restart ableton2ml"
    
    echo -e "${GREEN}Server updated${NC}"
}

show_outputs() {
    echo -e "${BLUE}Deployment Summary:${NC}"
    terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value.value)"' 2>/dev/null || terraform output
}

# Main script
check_requirements
get_project_info

case "${1:-help}" in
    deploy)
        deploy_infrastructure
        ;;
    destroy)
        destroy_infrastructure
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    ssh)
        ssh_to_server
        ;;
    restart)
        restart_server
        ;;
    monitor)
        show_monitoring
        ;;
    backup)
        create_backup
        ;;
    update)
        update_server
        ;;
    help|*)
        show_help
        ;;
esac
