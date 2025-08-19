#!/bin/bash

# Ableton2ML Terraform Deployment Script
# This script deploys the Ableton2ML infrastructure to Google Cloud

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars file not found!"
    print_status "Please copy terraform.tfvars.example to terraform.tfvars and update the values."
    exit 1
fi

# Check if HF_TOKEN is set in terraform.tfvars
if ! grep -q "hf_token" terraform.tfvars; then
    print_error "HF_TOKEN not found in terraform.tfvars!"
    print_status "Please add your Hugging Face token to terraform.tfvars"
    exit 1
fi

# Check if project_id is set
if ! grep -q "project_id" terraform.tfvars; then
    print_error "project_id not found in terraform.tfvars!"
    print_status "Please add your Google Cloud project ID to terraform.tfvars"
    exit 1
fi

print_status "Starting Ableton2ML deployment..."

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan the deployment
print_status "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo
print_warning "Review the plan above. Do you want to proceed with the deployment? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    print_success "Deployment completed successfully!"
    
    # Display outputs
    echo
    print_status "Deployment outputs:"
    echo "=================="
    
    if terraform output -json server_external_ip 2>/dev/null | grep -q "null"; then
        print_warning "Server external IP not available yet (may take a few minutes)"
    else
        SERVER_IP=$(terraform output -raw server_external_ip)
        print_success "Server External IP: $SERVER_IP"
        print_status "API Endpoint: http://$SERVER_IP:5001"
        print_status "Status Endpoint: http://$SERVER_IP:5001/api/status"
    fi
    
    if terraform output -json cloud_run_url 2>/dev/null | grep -q "null"; then
        print_warning "Cloud Run URL not available yet"
    else
        CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)
        print_success "Cloud Run URL: $CLOUD_RUN_URL"
    fi
    
    BUCKET_NAME=$(terraform output -raw bucket_name)
    print_success "Storage Bucket: $BUCKET_NAME"
    
    echo
    print_status "Next steps:"
    echo "1. Wait a few minutes for the server to fully start"
    echo "2. Test the API endpoints"
    echo "3. Access the server at http://$SERVER_IP:5001"
    echo "4. Check logs if needed: gcloud compute ssh ableton2ml-server --zone=us-central1-a"
    
else
    print_warning "Deployment cancelled."
    exit 0
fi
