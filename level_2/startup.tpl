#! /bin/bash
sudo apt-get update -y
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    mysql-client-core-8.0 \
    awscli -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo usermod -aG docker ubuntu
sudo su - ubuntu
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

RDS=$(echo ${rds_endpoint}| cut -d: -f1)

if mysql -u${username} -p${password} -h $RDS -e 'USE wordpress'
then
  echo "table exists already"
else
  aws s3 cp \
  s3://aws-terraform-wordpress-backups-bucket/wordpress_init_conf_dump.sql \
  wordpress_init_conf_dump.sql &&
  mysql -u${username} -p${password} -h $RDS -e 'CREATE DATABASE wordpress'
  mysqldump --column-statistics=0 \
  -u${username} -p${password} -h $RDS \
  wordpress < wordpress_init_conf_dump.sql &&
  echo "dump copied from S3"
fi

docker run --name WordPress -p 80:80 -d \
-e WORDPRESS_DB_HOST=${rds_endpoint} \
-e WORDPRESS_DB_USER=${username} \
-e WORDPRESS_DB_PASSWORD=${password} \
-e WORDPRESS_DB_NAME='wordpress' \
--name WordPress \
wordpress
