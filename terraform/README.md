# Ableton2ML Terraform Infrastructure

This Terraform configuration deploys the complete Ableton2ML infrastructure on Google Cloud Platform with Hugging Face model integration.

## 🚀 Features

- **Google Cloud Infrastructure**: Complete cloud setup with networking, compute, and storage
- **Hugging Face Integration**: Secure access to HF models using your HF_TOKEN
- **Compute Engine**: Dedicated server for the Ableton2ML application
- **Cloud Run**: Serverless API service (optional)
- **Vertex AI Workbench**: Jupyter notebook for model development (optional)
- **Secret Manager**: Secure storage of the HF_TOKEN
- **Cloud Storage**: Bucket for model storage and data

## 📋 Prerequisites

1. **Google Cloud Project**: You need a GCP project with billing enabled
2. **Google Cloud CLI**: Install and authenticate with `gcloud auth login`
3. **Terraform**: Install Terraform (version >= 1.0)
4. **Hugging Face Token**: Your HF_TOKEN for accessing models

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
# Navigate to the terraform directory
cd terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
# Required: Your Google Cloud Project ID
project_id = "your-google-cloud-project-id"

# Required: Your Hugging Face API Token
hf_token = "hf_your_huggingface_token_here"

# Optional: Customize as needed
region = "us-central1"
zone   = "us-central1-a"
```

### 3. Deploy Infrastructure

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

## 🏗️ Infrastructure Components

### Core Components

1. **VPC Network**: Custom network with firewall rules
2. **Compute Engine Instance**: Server running Ableton2ML
3. **Service Account**: IAM roles for secure access
4. **Secret Manager**: Stores HF_TOKEN securely
5. **Cloud Storage**: Bucket for models and data

### Optional Components

1. **Cloud Run Service**: Serverless API endpoint
2. **Vertex AI Workbench**: Jupyter notebook for development

## 🔧 Configuration Options

### Instance Configuration

```hcl
# Basic instance (CPU only)
instance_machine_type = "n1-standard-4"
enable_gpu           = false

# GPU instance for faster model inference
instance_machine_type = "n1-standard-4"
enable_gpu           = true
gpu_type            = "nvidia-tesla-t4"
gpu_count           = 1
```

### Environment Configuration

```hcl
# Development environment
environment = "dev"
enable_cloud_run = false
enable_notebook  = true

# Production environment
environment = "prod"
enable_cloud_run = true
enable_notebook  = false
```

## 🔐 Security Features

### HF_TOKEN Security

- **Secret Manager**: Token stored securely in Google Secret Manager
- **IAM Access**: Service account has minimal required permissions
- **Environment Variables**: Token passed securely to applications

### Network Security

- **VPC**: Isolated network environment
- **Firewall Rules**: Controlled access to ports 22, 80, 443, 5001
- **Service Account**: No default credentials

## 📊 Outputs

After deployment, you'll get:

- **Server External IP**: Public IP of the Compute Engine instance
- **Cloud Run URL**: Serverless API endpoint (if enabled)
- **Storage Bucket**: Name of the Cloud Storage bucket
- **Notebook URL**: Vertex AI Workbench URL (if enabled)

## 🧪 Testing the Deployment

### 1. Check Server Status

```bash
# Get the server IP
SERVER_IP=$(terraform output -raw server_external_ip)

# Test the API
curl http://$SERVER_IP:5001/api/status
```

### 2. Test HF Token Integration

```bash
# Test HF token validation
curl http://$SERVER_IP:5001/api/hf/status

# Test model search
curl http://$SERVER_IP:5001/api/hf/models
```

### 3. Test Magenta Models

```bash
# Get available Magenta models
curl http://$SERVER_IP:5001/api/magenta/models
```

## 🔄 Updating the Deployment

### Add GPU Support

```bash
# Edit terraform.tfvars
enable_gpu = true
gpu_type  = "nvidia-tesla-t4"

# Apply changes
terraform plan
terraform apply
```

### Update HF Token

```bash
# Edit terraform.tfvars with new token
hf_token = "hf_new_token_here"

# Apply changes
terraform apply
```

## 🗑️ Cleanup

To destroy the infrastructure:

```bash
# Destroy all resources
terraform destroy

# Confirm with 'yes' when prompted
```

## 📝 Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure your GCP account has necessary permissions
2. **API Not Enabled**: The deployment automatically enables required APIs
3. **Token Invalid**: Verify your HF_TOKEN is correct and has proper permissions
4. **Server Not Starting**: Check startup logs with `gcloud compute ssh`

### Useful Commands

```bash
# SSH to the server
gcloud compute ssh ableton2ml-server --zone=us-central1-a

# Check server logs
gcloud compute ssh ableton2ml-server --zone=us-central1-a --command='sudo journalctl -u ableton2ml -f'

# Check Terraform state
terraform show

# Validate configuration
terraform validate
```

## 🔗 Integration with Ableton Live

Once deployed, update your Ableton2ML plugin configuration:

1. **Server URL**: Use the server external IP
2. **API Endpoint**: `http://SERVER_IP:5001`
3. **HF Token**: Automatically handled by the server

## 📚 Additional Resources

- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Hugging Face API Documentation](https://huggingface.co/docs/api-inference)
- [Ableton2ML Project Documentation](../README.md)

---

**Note**: This infrastructure is designed for development and testing. For production use, consider additional security measures and monitoring.
