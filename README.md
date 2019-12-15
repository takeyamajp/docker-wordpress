# wordpress
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![license](https://img.shields.io/github/license/takeyamajp/docker-wordpress.svg)](https://github.com/takeyamajp/docker-wordpress/blob/master/LICENSE)

### Supported tags and respective Dockerfile links  
- [`latest`, `centos8`](https://github.com/takeyamajp/docker-wordpress/blob/master/centos8/Dockerfile)
- [`centos7`](https://github.com/takeyamajp/docker-wordpress/blob/master/centos7/Dockerfile)

### Image summary
    FROM centos:centos8  
    MAINTAINER "Hiroki Takeyama"
    
    ENV TIMEZONE Asia/Tokyo
    
    ENV REQUIRE_SSL true  
    ENV GZIP_COMPRESSION true
    
    ENV BASIC_AUTH false  
    ENV BASIC_AUTH_USER user  
    ENV BASIC_AUTH_PASSWORD user
    
    ENV HTTPD_SERVER_ADMIN root@localhost  
    ENV HTTPD_LOG true  
    ENV HTTPD_LOG_LEVEL warn  
    ENV HTTPD_PHP_ERROR_LOG true
    
    VOLUME /wordpress
    
    EXPOSE 80  
    EXPOSE 443
