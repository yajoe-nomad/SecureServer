FROM httpd:2.4-alpine

# WebDAV 관련 모듈 활성화
RUN sed -i \
    -e 's/#LoadModule dav_module/LoadModule dav_module/' \
    -e 's/#LoadModule dav_fs_module/LoadModule dav_fs_module/' \
    -e 's/#LoadModule auth_digest_module/LoadModule auth_digest_module/' \
    /usr/local/apache2/conf/httpd.conf

# 설정 파일 복사
COPY webdav.conf /usr/local/apache2/conf/extra/webdav.conf

# httpd.conf 에 webdav.conf 를 include
RUN echo "Include conf/extra/webdav.conf" >> /usr/local/apache2/conf/httpd.conf

# WebDAV 잠금 파일 디렉토리
RUN mkdir -p /usr/local/apache2/var/

# 파일 저장 디렉토리
RUN mkdir -p /var/webdav && \
    chown -R daemon:daemon /var/webdav

# entrypoint 스크립트 복사
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]