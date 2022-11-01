variable "region" {
  description = "Your target AWS region"
  default     = "us-west-1"
  type        = string
}

variable "owner" {
  description = "Owner of resources"
  default     = "NGINX APIg demo runner"
  type        = string
}

variable "key_data" {
  description = "The key used to ssh into your AWS instance"
  # default = {
  #   name     = "johndoe"
  #   location = "~/.ssh/johndoe.pem"
  # }
  type = map(string)
}

variable "r53_zone" {
  description = "R53 hosted zone ID"
  type        = string
}

variable "nginx_api_gateway_machine_type" {
  description = "The AWS machine type for your NGINX API gateway"
  default     = "t2.medium"
  type        = string
}

variable "nginx_api_gateway_fqdn" {
  description = "NGINX API gateway FQDN"
  type        = string
}

variable "nginx_plus_license" {
  description = "Location of NGINX Plus license to be used in agent instance"
  # default = {
  #   key  = "nginx_license/nginx-repo.key"
  #   cert = "nginx_license/nginx-repo.crt"
  # }
  type = map(string)
}

variable "nginx_api_gateway_certbot" {
  description = "Use certbot to automate cert generation for the NGINX API gateway"
  default     = false
  type        = bool
}

variable "upload_nginx_api_gateway_config_files" {
  description = "Upload NGINX API gateway sample files"
  default     = true
  type        = bool
}

variable "backend_api_machine_type" {
  description = "The AWS machine type for your API workload backend"
  default     = "t2.medium"
  type        = string
}

variable "backend_api_fqdn" {
  description = "Backend API gateway FQDN"
  type        = string
}

variable "backend_api_certbot" {
  description = "Use certbot to automate cert generation for the backend API"
  default     = false
  type        = bool
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"]
}
