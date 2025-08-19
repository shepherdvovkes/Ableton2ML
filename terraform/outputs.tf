# Ableton2ML Terraform Outputs

output "gpu_server_external_ip" {
  description = "External IP address of the GPU server"
  value       = google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip
}

output "gpu_server_internal_ip" {
  description = "Internal IP address of the GPU server"
  value       = google_compute_instance.magenta_gpu_server.network_interface[0].network_ip
}

output "cpu_server_external_ip" {
  description = "External IP address of the CPU server (if created)"
  value       = var.create_cpu_instance ? google_compute_instance.magenta_cpu_server[0].network_interface[0].access_config[0].nat_ip : null
}

output "api_endpoint" {
  description = "API endpoint for the Ableton2ML server"
  value       = "http://${google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip}:5001"
}

output "status_endpoint" {
  description = "Status endpoint for the Ableton2ML server"
  value       = "http://${google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip}:5001/api/status"
}

output "hf_status_endpoint" {
  description = "Hugging Face status endpoint"
  value       = "http://${google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip}:5001/api/hf/status"
}

output "storage_bucket" {
  description = "Cloud Storage bucket name for models and data"
  value       = google_storage_bucket.ableton2ml_bucket.name
}

output "terraform_state_bucket" {
  description = "Cloud Storage bucket name for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.ableton2ml_network.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.ableton2ml_subnet.name
}

output "gpu_instance_name" {
  description = "GPU instance name"
  value       = google_compute_instance.magenta_gpu_server.name
}

output "cpu_instance_name" {
  description = "CPU instance name (if created)"
  value       = var.create_cpu_instance ? google_compute_instance.magenta_cpu_server[0].name : null
}

output "ssh_command_gpu" {
  description = "SSH command to connect to GPU server"
  value       = "gcloud compute ssh ${google_compute_instance.magenta_gpu_server.name} --zone=${var.zone}"
}

output "ssh_command_cpu" {
  description = "SSH command to connect to CPU server (if created)"
  value       = var.create_cpu_instance ? "gcloud compute ssh ${google_compute_instance.magenta_cpu_server[0].name} --zone=${var.zone}" : null
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project_id        = var.project_id
    region           = var.region
    zone             = var.zone
    gpu_server_ip    = google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip
    cpu_server_ip    = var.create_cpu_instance ? google_compute_instance.magenta_cpu_server[0].network_interface[0].access_config[0].nat_ip : null
    api_endpoint     = "http://${google_compute_instance.magenta_gpu_server.network_interface[0].access_config[0].nat_ip}:5001"
    storage_bucket   = google_storage_bucket.ableton2ml_bucket.name
    gpu_type         = var.gpu_type
    gpu_count        = var.gpu_count
  }
}
