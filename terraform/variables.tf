variable "aws_region" {
  description = "AWS 리전"
  type = string
}

variable "project_name" {
  description = "프로젝트 이름"
  type = string
}

variable "repository" {
  description = "GitHub 저장소 URL"
  type = string
}

variable "webdav_user" {
  description = "WebDAV 사용자 이름"
  type = string
}

variable "webdav_password" {
  description = "WebDAV 비밀번호"
  type = string
  sensitive = true # Terraform 상태 파일, 로그에서 암호화 되어 저장
}

variable "wg_peers" {
  description = "WireGuard 피어 수"
  type = number
  default = 1
}

variable "wg_port" {
  description = "WireGuard 포트"
  type = number
  default = 51820
}

variable "ssh_public_key" {
  description = "SSH 공개키"
  type = string
}

# AMI는 경량화되어 있고 관리할 필요가 없는 Amazon Linux 2023을 사용
variable "ami_id" {
  description = "Amazon Linux 2023(서울 리전)"
  type = string
  default = "ami-00e1a894b4512388e"
}

variable "ssh_port" {
  description = "SSH 포트"
  type        = number
}