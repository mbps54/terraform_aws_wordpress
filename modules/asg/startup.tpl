#! /bin/bash
sudo apt-get update -y
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo usermod -aG docker ubuntu
sudo su - ubuntu
docker run --name WordPress -p 80:80 -d \
-e WORDPRESS_DB_HOST=${rds_endpoint} \
-e WORDPRESS_DB_USER=${username} \
-e WORDPRESS_DB_PASSWORD=${password} \
-e WORDPRESS_DB_NAME='wordpress' \
--name WordPress \
wordpress
