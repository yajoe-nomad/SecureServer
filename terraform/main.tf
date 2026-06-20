terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # /24 는 조금 작아보여
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 서브넷
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# IG
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 라우팅 : 인터넷 게이트웨이로 모든 트래픽 라우팅
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table & Subnet 연결
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 시큐리티 그룹
resource "aws_security_group" "main" {
  name = "${var.project_name}-SG"
  description = "${var.project_name} security group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 51820
    to_port = 51820
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "WireGuard VPN"
  }

  ingress {
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-SG"
  }
}

# EIP
resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

# SSH 키페어
resource "aws_key_pair" "main" {
  key_name = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.project_name}-key"
  }
}

# EC2 인스턴스
resource "aws_instance" "main" {
  ami = var.ami_id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name = aws_key_pair.main.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # 시스템 업데이트
    dnf update -y

    # SSH 포트 변경(22 -> 22222)
    sed -i 's/#Port 22/Port ${var.ssh_port}/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Docker 설치
    dnf install -y docker git
    systemctl enable docker
    systemctl start docker

    # Docker Compose 설치
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Docker buildx 설치
    # AL2023에는 buildx가 기본적으로 포함되어 있지만, 0.17.0 이상이 필요하므로 별도로 설치
    mkdir -p ~/.docker/cli-plugins
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
    BUILDX_URL=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep "browser_download_url.*linux-$ARCH" | cut -d '"' -f 4)
    curl -L $BUILDX_URL -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx

    # 프로젝트 디렉토리 생성
    mkdir -p /app/repo
    cd /app/repo

    # docker-compose.yml 복사는 GitHub에서 clone 하도록
    git clone https://github.com/${var.repository}.git ./

    # .env 파일 생성
    echo "WEBDAV_USER=${var.webdav_user}" >> .env
    echo "WEBDAV_PASSWORD=${var.webdav_password}" >> .env
    echo "WEBDAV_INTERNAL_PORT=80" >> .env
    echo "WG_HOST=${aws_eip.main.public_ip}" >> .env
    echo "WG_PORT=${var.wg_port}" >> .env
    echo "WG_PEERS=${var.wg_peers}" >> .env

    # 컨테이너 시작
    docker-compose up -d
  EOF

  tags = {
    Name = "${var.project_name}-EC2"
  }
}

# EIP를 EC2에 연결
resource "aws_eip_association" "main" {
  instance_id = aws_instance.main.id
  allocation_id = aws_eip.main.id
}