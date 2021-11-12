# NGINX API Gateway instance(s)
# The number of deployed instances can be tweaked using the count variable
# Installs NGINX Plus by default
resource "aws_instance" "nginx_api_gateway" {
  # count         = var.nginx_api_gateway_count
  ami           = var.ami
  instance_type = var.nginx_api_gateway_machine_type
  key_name      = var.key_data["name"]
  vpc_security_group_ids = [
    aws_security_group.nginx_api_gateway.id,
  ]
  subnet_id = aws_subnet.main.id
  user_data = <<EOF
#!/bin/sh
set -ex
apt update
apt install -y apt-transport-https ca-certificates lsb-release
mkdir /etc/ssl/nginx
cat > /etc/ssl/nginx/nginx-repo.crt << EOL
${file(var.nginx_plus_license["cert"])}
EOL
cat > /etc/ssl/nginx/nginx-repo.key << EOL
${file(var.nginx_plus_license["key"])}
EOL
wget https://cs.nginx.com/static/keys/nginx_signing.key
wget https://cs.nginx.com/static/keys/app-protect-security-updates.key
apt-key add nginx_signing.key
apt-key add app-protect-security-updates.key
printf "deb https://pkgs.nginx.com/plus/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list
printf "deb https://pkgs.nginx.com/app-protect/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-app-protect.list
printf "deb https://pkgs.nginx.com/app-protect-security-updates/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee -a /etc/apt/sources.list.d/nginx-app-protect.list
wget -q -O /etc/apt/apt.conf.d/90pkgs-nginx https://cs.nginx.com/static/files/90pkgs-nginx
apt update
apt install -y nginx-plus nginx-plus-module-njs app-protect app-protect-attack-signatures jq
service nginx start
EOF
  tags = {
    Name  = "nginx_api_gateway",
    Owner = var.owner,
    user  = "ubuntu",
  }
}

# Enable SSL on NGINX API gateway
resource "null_resource" "tweak_nginx_api_gateway_config" {
  count = var.nginx_api_gateway_certbot ? 1 : 0
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "while [ ! -f /etc/nginx/nginx.conf ]; do sleep 5; done",
      "sudo snap install core",
      "sudo snap refresh core",
      "sudo snap install --classic certbot",
      "sudo ln -s /certbot /usr/bin/certbot",
      "sudo certbot --nginx --redirect --agree-tos --register-unsafely-without-email -d ${aws_route53_record.nginx_api_gateway.fqdn}",
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_data["location"])
    host        = aws_route53_record.nginx_api_gateway.fqdn
  }
  depends_on = [
    aws_instance.nginx_api_gateway,
  ]
}

# Upload NGINX configuration files to NGINX API gateway
resource "null_resource" "upload_nginx_api_gateway_config_files" {
  count = var.upload_nginx_api_gateway_config_files ? 1 : 0
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "while [ ! -f /etc/nginx/nginx.conf ]; do sleep 5; done",
    ]
  }
  provisioner "file" {
    source      = "api_gateway_files"
    destination = "/home/ubuntu"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_data["location"])
    host        = aws_route53_record.nginx_api_gateway.fqdn
  }
  depends_on = [
    aws_instance.nginx_api_gateway,
  ]
}
