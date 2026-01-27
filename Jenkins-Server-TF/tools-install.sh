#!/bin/bash
# For Ubuntu 22.04

set -e  # Exit on error

# Update system
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl

# Create keyrings directory if not exists
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# List available Docker versions
apt-cache madison docker-ce | awk '{ print $3 }'

# Install specific Docker version
VERSION_STRING=5:28.1.0-1~ubuntu.22.04~jammy

sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

# Reload system
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start docker

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl restart docker

# Setting sudo permitions
sudo usermod -aG docker ubuntu

# Installing AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Create the Jenkins Workspace
mkdir -p /opt/jenkins

# Create docker-compose.yml file for Jenkins
cat <<EOF | sudo tee /opt/jenkins/docker-compose.yml
services:
  jenkins:
    image: freelancerdev/jenkins-server:latest
    container_name: jenkins-server
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Djava.util.logging.config.file=/var/jenkins_home/log.properties
      - CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml
    ports:
      - '8880:8080'
    volumes:
      - jenkins-vol:/var/jenkins_home
      - ./jenkins.yaml:/var/jenkins_home/jenkins.yaml:ro
      - /usr/bin/docker:/usr/bin/docker:ro
      - /var/run/docker.sock:/var/run/docker.sock
    group_add:
      - 999

volumes:
  jenkins-vol:
    driver: local

EOF

# Start Jenkins container
(cd /opt/jenkins && sudo docker compose up -d)

# Create the Gitlab Workspace
mkdir -p /opt/gitlab

# Create docker-compose.yml file for Gitlab
cat <<EOF | tee /opt/gitlab/docker-compose.yml
services:
  gitlab:
    image: gitlab/gitlab-ce
    container_name: gitlab
    restart: always
    hostname: 'gitlab.isaac.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:80'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
        letsencrypt['enable'] = false

        puma['worker_processes']  = 0

        prometheus['enable']                     = false
        alertmanager['enable']                   = false
        node_exporter['enable']                  = false
        redis_exporter['enable']                 = false
        postgres_exporter['enable']              = false
        gitlab_exporter['enable']                = false

        gitlab_rails['performance_bar_enabled']  = false
        gitlab_rails['enable_influxdb']          = false
    ports:
      - '80:80'    # HTTP port
      - '443:443'      # HTTPS port
      - '2424:22'      # SSH port
    volumes:
      - '/srv/gitlab/config:/etc/gitlab:z'
      - '/srv/gitlab/logs:/var/log/gitlab:z'
      - '/srv/gitlab/data:/var/opt/gitlab:z'

EOF

# Create the Sonarqube Workspace
mkdir -p /opt/sonarqube

# Create docker-compose.yml file for Sonarqube
cat <<EOF | tee /opt/sonarqube/docker-compose.yml
services:
  sonarqube:
    image: sonarqube:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    # environment:
      # Ejemplo: si quieres usar la base de datos integrada H2, no necesitas definir SONAR_JDBC_URL
      # Si usarás PostgreSQL u otra, define aquí SONAR_JDBC_URL, SONAR_JDBC_USERNAME, SONAR_JDBC_PASSWORD
      # SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      # SONAR_JDBC_USERNAME: sonar
      # SONAR_JDBC_PASSWORD: sonar
      # Puedes agregar otras variables como JAVA_TOOL_OPTIONS, SONAR_WEB_JAVAADDITIONALOPTS etc.
      # Ejemplo para IPv6:
      # JAVA_TOOL_OPTIONS: "-Djava.net.preferIPv6Addresses=true"
      # SONAR_WEB_JAVAADDITIONALOPTS: "-Djava.net.preferIPv6Addresses=true"
    restart: unless-stopped

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:

EOF

# Start Sonarqube container
(cd /opt/sonarqube && sudo docker compose up -d)

# Allow firewall access
sudo ufw allow 8880/tcp
sudo ufw allow 9000/tcp
sudo ufw allow 2424/tcp
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
