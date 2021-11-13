# Mock NGINX Plus Sports API containing mock Baseball, Golf, and Tennis data
# Also launches an Ergast F1 API container
resource "aws_instance" "backend_api" {
  ami           = data.aws_ami.distro.id
  instance_type = var.backend_api_machine_type
  key_name      = var.key_data["name"]
  vpc_security_group_ids = [
    aws_security_group.backend_api.id,
  ]
  subnet_id = aws_subnet.main.id
  user_data = <<EOF
#!/bin/sh
set -ex
apt update
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg-agent \
    jq \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
git clone https://github.com/jcnewell/ergast-f1-api.git /home/ubuntu/ergast-f1-api
sed -i -e 's/FROM mysql/FROM mysql:5.6/g' /home/ubuntu/ergast-f1-api/ergastdb/Dockerfile
sed -i 's/$format = "xml";/$format = "json";/' /home/ubuntu/ergast-f1-api/webroot/php/api/index.php
docker-compose -f /home/ubuntu/ergast-f1-api/docker-compose.yaml up --build  -d --remove-orphans

set -ex
mkdir /etc/ssl/nginx
cat > /etc/ssl/nginx/nginx-repo.crt << EOL
${file(var.nginx_plus_license["cert"])}
EOL
cat > /etc/ssl/nginx/nginx-repo.key << EOL
${file(var.nginx_plus_license["key"])}
EOL
wget https://cs.nginx.com/static/keys/nginx_signing.key
apt-key add nginx_signing.key
apt install -y apt-transport-https ca-certificates lsb-release
printf "deb https://pkgs.nginx.com/plus/ubuntu `lsb_release -cs` nginx-plus\n" | tee /etc/apt/sources.list.d/nginx-plus.list
wget -q -O /etc/apt/apt.conf.d/90pkgs-nginx https://cs.nginx.com/static/files/90pkgs-nginx
apt update
apt install -y nginx-plus nginx-plus-module-njs
sed -i '1iload_module modules/ngx_http_js_module.so;' /etc/nginx/nginx.conf
cat > /etc/nginx/conf.d/default.conf <<'EOL'
${templatefile("backend_api/default.conf", {
  fqdn = 0,
})}
EOL
cat > /etc/nginx/conf.d/echo.js <<EOL
${file("backend_api/echo.js")}
EOL
nginx
EOF
tags = {
  Name  = "backend_api",
  Owner = var.owner,
  user  = "ubuntu",
}
}

# Enable SSL on backend API
resource "null_resource" "tweak_backend_api_config" {
  count = var.backend_api_certbot ? 1 : 0
  provisioner "file" {
    content = templatefile("backend_api/default.conf", {
      fqdn = aws_route53_record.backend_api.fqdn
    })
    destination = "/home/ubuntu/default.conf"
  }
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "while [ ! -f /etc/nginx/conf.d/echo.js ]; do sleep 5; done",
      "sudo snap install core",
      "sudo snap refresh core",
      "sudo snap install --classic certbot",
      "sudo ln -s /certbot /usr/bin/certbot",
      "sudo certbot certonly --nginx --agree-tos --register-unsafely-without-email -d ${aws_route53_record.backend_api.fqdn}",
      "sudo mv /home/ubuntu/default.conf /etc/nginx/conf.d/default.conf",
      "sudo nginx -s reload",
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_data["location"])
    host        = aws_route53_record.backend_api.fqdn
  }
  depends_on = [
    aws_instance.backend_api,
  ]
}
