# Terraform configuration for Ableton2ML with Hugging Face integration
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Configure Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Variables
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "your-project-id"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "us-central1-a"
}

variable "hf_token" {
  description = "Hugging Face API Token"
  type        = string
  sensitive   = true
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create a service account for the application
resource "google_service_account" "ableton2ml_sa" {
  account_id   = "ableton2ml-sa"
  display_name = "Ableton2ML Service Account"
  description  = "Service account for Ableton2ML application"
}

# Grant necessary roles to the service account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/storage.admin",
    "roles/aiplatform.user",
    "roles/cloudbuild.builds.builder"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ableton2ml_sa.email}"
}

# Create a secret for the HF_TOKEN
resource "google_secret_manager_secret" "hf_token_secret" {
  secret_id = "hf-token"
  
  replication {
    auto {}
  }
}

# Store the HF_TOKEN in Secret Manager
resource "google_secret_manager_secret_version" "hf_token_version" {
  secret      = google_secret_manager_secret.hf_token_secret.id
  secret_data = var.hf_token
}

# Grant access to the secret
resource "google_secret_manager_secret_iam_member" "secret_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.hf_token_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ableton2ml_sa.email}"
}

# Create a VPC network
resource "google_compute_network" "ableton2ml_network" {
  name                    = "ableton2ml-network"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "ableton2ml_subnet" {
  name          = "ableton2ml-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.ableton2ml_network.id
  region        = var.region
}

# Create firewall rules
resource "google_compute_firewall" "ableton2ml_firewall" {
  name    = "ableton2ml-firewall"
  network = google_compute_network.ableton2ml_network.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ableton2ml"]
}

# Create a Cloud Storage bucket for models and data
resource "google_storage_bucket" "ableton2ml_bucket" {
  name          = "${var.project_id}-ableton2ml-models"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Create a Compute Engine instance for the application
resource "google_compute_instance" "ableton2ml_server" {
  name         = "ableton2ml-server"
  machine_type = "n1-standard-4"
  zone         = var.zone

  tags = ["ableton2ml", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.ableton2ml_network.id
    subnetwork = google_compute_subnetwork.ableton2ml_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    hf-token-secret = google_secret_manager_secret.hf_token_secret.secret_id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Install Python and dependencies
    apt-get update
    apt-get install -y python3 python3-pip git curl
    
    # Clone the repository
    git clone https://github.com/your-repo/ableton2ml.git /opt/ableton2ml
    cd /opt/ableton2ml
    
    # Install Python dependencies
    pip3 install -r requirements_simple.txt
    
    # Create environment file with HF_TOKEN
    echo "HF_TOKEN=${var.hf_token}" > /opt/ableton2ml/.env
    
    # Start the server
    cd /opt/ableton2ml
    nohup python3 server/magenta_server.py > /var/log/ableton2ml.log 2>&1 &
  EOF

  service_account {
    email  = google_service_account.ableton2ml_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.required_apis,
    google_secret_manager_secret_version.hf_token_version
  ]
}

# Create a Cloud Run service for the API
resource "google_cloud_run_service" "ableton2ml_api" {
  name     = "ableton2ml-api"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/ableton2ml:latest"
        
        env {
          name  = "HF_TOKEN"
          value = var.hf_token
        }
        
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        
        ports {
          container_port = 5001
        }
        
        resources {
          limits = {
            cpu    = "2000m"
            memory = "4Gi"
          }
        }
      }
      
      service_account_name = google_service_account.ableton2ml_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Make the Cloud Run service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.ableton2ml_api.location
  service  = google_cloud_run_service.ableton2ml_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Create Vertex AI Workbench for model development
resource "google_notebooks_instance" "ableton2ml_notebook" {
  name         = "ableton2ml-notebook"
  location     = var.region
  machine_type = "n1-standard-4"

  vm_image {
    project      = "deeplearning-platform-release"
    image_family = "tf-latest-gpu"
  }

  instance_owners = ["user:your-email@example.com"]

  metadata = {
    proxy-mode = "service_account"
    hf-token   = var.hf_token
  }
}

# Outputs
output "server_external_ip" {
  value = google_compute_instance.ableton2ml_server.network_interface[0].access_config[0].nat_ip
}

output "cloud_run_url" {
  value = google_cloud_run_service.ableton2ml_api.status[0].url
}

output "notebook_url" {
  value = google_notebooks_instance.ableton2ml_notebook.proxy_uri
}

output "bucket_name" {
  value = google_storage_bucket.ableton2ml_bucket.name
}
