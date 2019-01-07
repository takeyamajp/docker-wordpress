# wordpress
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![license](https://img.shields.io/github/license/takeyamajp/docker-wordpress.svg)](https://github.com/takeyamajp/docker-wordpress/blob/master/LICENSE)

    FROM centos:centos7  
    MAINTAINER "Hiroki Takeyama"
    
    ENV TIMEZONE Asia/Tokyo
    
    ENV REQUIRE_SSL true  
    ENV ENABLE_GZIP_COMPRESSION true
    
    ENV REQUIRE_BASIC_AUTH false  
    ENV BASIC_AUTH_USER user  
    ENV BASIC_AUTH_PASSWORD user
    
    ENV HTTPD_LOGGING true  
    ENV HTTPD_LOG_LEVEL warn
    
    VOLUME /wordpress
    
    EXPOSE 80  
    EXPOSE 443
