output "elastic_ip" {
  description = "WireGuard 서버 고정 IP"
  value = aws_eip.main.public_ip
}

output "ec2_instance_id" {
  description = "EC2 인스턴스 ID"
  value = aws_instance.main.id
}

output "ec2_public_ip" {
  description = "EC2 퍼블릭 IP (EIP 연결 전)"
  value = aws_instance.main.public_ip
}

output "wireguard_endpoint" {
  description = "WireGuard 클라이언트 설정용 Endpoint"
  value = "${aws_eip.main.public_ip}:51820"
}

output "webdav_url" {
  description = "WebDAV 접속 URL (VPN 연결 후)"
  value = "http://10.13.13.1/webdav/"
}

output "ssh_command" {
  description = "EC2 SSH 접속 커맨드"
  value = "ssh -i ~/.ssh/id_rsa -p ${var.ssh_port} ec2-user@${aws_eip.main.public_ip}"
}