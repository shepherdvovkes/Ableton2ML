# 🚀 Terraform Deployment with Hugging Face Integration

## Overview

This Terraform configuration deploys a complete Google Cloud infrastructure for Ableton2ML with secure Hugging Face model access using your HF_TOKEN.

## ✅ What's Included

### 🏗️ Infrastructure Components

1. **VPC Network & Security**
   - Custom VPC with isolated subnet
   - Firewall rules for secure access
   - Service account with minimal permissions

2. **Compute Resources**
   - Compute Engine instance (n1-standard-4)
   - Optional GPU support (Tesla T4)
   - Automatic startup script with HF_TOKEN integration

3. **Cloud Services**
   - Cloud Storage bucket for models
   - Secret Manager for HF_TOKEN storage
   - Optional Cloud Run service
   - Optional Vertex AI Workbench

4. **Security Features**
   - HF_TOKEN stored in Google Secret Manager
   - IAM roles with least privilege
   - Secure environment variable handling

## 🔧 Configuration Files

### Core Files
- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars.example` - Example configuration
- `deploy.sh` - Automated deployment script
- `README.md` - Detailed documentation

### Key Features
- **HF_TOKEN Integration**: Secure token management
- **Modular Design**: Optional components (GPU, Cloud Run, Notebook)
- **Environment Support**: Dev/Staging/Prod configurations
- **Automated Deployment**: One-command deployment

## 🛠️ Quick Deployment

### 1. Setup Configuration
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables
Edit `terraform.tfvars`:
```hcl
project_id = "your-google-cloud-project-id"
hf_token   = "hf_rqeQxHm...nNewBLQzny"  # Your working token
region     = "us-central1"
zone       = "us-central1-a"
```

### 3. Deploy
```bash
./deploy.sh
```

## 🔐 HF_TOKEN Security

### Secure Storage
- **Secret Manager**: Token stored in Google Secret Manager
- **IAM Access**: Service account has access to secret
- **Environment Variables**: Token passed securely to applications

### Integration Points
- **Startup Script**: Token injected during instance startup
- **Cloud Run**: Token available as environment variable
- **Notebook**: Token available in metadata

## 📊 Deployment Outputs

After successful deployment:

```bash
# Server Information
Server External IP: 34.123.45.67
API Endpoint: http://34.123.45.67:5001
Status Endpoint: http://34.123.45.67:5001/api/status

# Cloud Services
Cloud Run URL: https://ableton2ml-api-abc123.run.app
Storage Bucket: your-project-ableton2ml-models
```

## 🧪 Testing Integration

### 1. Test Server Status
```bash
curl http://SERVER_IP:5001/api/status
```

### 2. Test HF Token
```bash
curl http://SERVER_IP:5001/api/hf/status
```

### 3. Test Model Access
```bash
curl http://SERVER_IP:5001/api/hf/models
```

## 🔄 Configuration Options

### GPU Support
```hcl
enable_gpu = true
gpu_type  = "nvidia-tesla-t4"
gpu_count = 1
```

### Environment Types
```hcl
# Development
environment = "dev"
enable_cloud_run = false
enable_notebook  = true

# Production
environment = "prod"
enable_cloud_run = true
enable_notebook  = false
```

## 📈 Cost Estimation

### Monthly Costs (us-central1)
- **Compute Engine (n1-standard-4)**: ~$150/month
- **GPU (Tesla T4)**: ~$250/month (if enabled)
- **Cloud Storage (50GB)**: ~$1/month
- **Secret Manager**: ~$0.06/month
- **Network**: ~$10/month

**Total**: ~$160-410/month depending on GPU usage

## 🔗 Integration with Ableton2ML

### Plugin Configuration
1. **Server URL**: Use the deployed server IP
2. **API Endpoint**: `http://SERVER_IP:5001`
3. **Authentication**: HF_TOKEN handled automatically

### Available Endpoints
- `GET /api/status` - Server status
- `GET /api/hf/status` - HF token validation
- `GET /api/hf/models` - Search HF models
- `GET /api/magenta/models` - List Magenta models
- `POST /api/generate/*` - Music generation endpoints

## 🚨 Important Notes

### Security Considerations
- **Firewall**: Only ports 22, 80, 443, 5001 open
- **Access**: Public IP for development (consider VPN for production)
- **Credentials**: No default credentials, uses service account

### Best Practices
- **Backup**: Regular backups of Terraform state
- **Monitoring**: Set up Cloud Monitoring for production
- **Updates**: Keep Terraform and dependencies updated
- **Cost Control**: Stop instances when not in use

## 🗑️ Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## 📝 Troubleshooting

### Common Issues
1. **Permission Denied**: Check GCP project permissions
2. **API Not Enabled**: Deployment auto-enables required APIs
3. **Token Issues**: Verify HF_TOKEN is valid
4. **Server Not Starting**: Check startup logs

### Useful Commands
```bash
# SSH to server
gcloud compute ssh ableton2ml-server --zone=us-central1-a

# Check logs
gcloud compute ssh ableton2ml-server --zone=us-central1-a --command='sudo journalctl -u ableton2ml -f'

# Validate Terraform
terraform validate
```

---

## 🎯 Next Steps

1. **Deploy Infrastructure**: Run `./deploy.sh`
2. **Test Integration**: Verify HF token and model access
3. **Configure Plugin**: Update Ableton2ML plugin with server IP
4. **Monitor Usage**: Set up monitoring and cost alerts
5. **Scale as Needed**: Add GPU support or Cloud Run for production

**Status**: ✅ Ready for deployment with working HF_TOKEN integration!
