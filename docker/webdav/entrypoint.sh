#!/bin/sh

# 환경변수로 .htpasswd 자동 생성
htpasswd -cb /usr/local/apache2/conf/.htpasswd "$WEBDAV_USER" "$WEBDAV_PASSWORD"

# Apache 실행
httpd-foreground