# Variables for Ableton2ML Terraform configuration

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

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_machine_type" {
  description = "Machine type for Compute Engine instance"
  type        = string
  default     = "n1-standard-4"
}

variable "enable_gpu" {
  description = "Enable GPU support for the instance"
  type        = bool
  default     = false
}

variable "gpu_type" {
  description = "GPU type (if enable_gpu is true)"
  type        = string
  default     = "nvidia-tesla-t4"
}

variable "gpu_count" {
  description = "Number of GPUs (if enable_gpu is true)"
  type        = number
  default     = 1
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "enable_cloud_run" {
  description = "Enable Cloud Run service"
  type        = bool
  default     = true
}

variable "enable_notebook" {
  description = "Enable Vertex AI Workbench notebook"
  type        = bool
  default     = false
}

variable "notebook_owners" {
  description = "List of users who can access the notebook"
  type        = list(string)
  default     = []
}

variable "repository_url" {
  description = "Git repository URL for the Ableton2ML code"
  type        = string
  default     = "https://github.com/your-repo/ableton2ml.git"
}

variable "branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}
