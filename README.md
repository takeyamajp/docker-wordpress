# wordpress
Star this repository if it is useful for you.  
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/wordpress.svg)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![license](https://img.shields.io/github/license/takeyamajp/docker-wordpress.svg)](https://github.com/takeyamajp/docker-wordpress/blob/master/LICENSE)

## Supported tags and respective Dockerfile links  
- [`latest`, `rocky9`](https://github.com/takeyamajp/docker-wordpress/blob/master/rocky9/Dockerfile) (Rocky Linux 9) [`alma9`](https://github.com/takeyamajp/docker-wordpress/blob/master/alma9/Dockerfile) (AlmaLinux 9)
- [`rocky8`](https://github.com/takeyamajp/docker-wordpress/blob/master/rocky8/Dockerfile) (Rocky Linux 8) [`alma8`](https://github.com/takeyamajp/docker-wordpress/blob/master/alma8/Dockerfile) (AlmaLinux 8)
- [`centos8`](https://github.com/takeyamajp/docker-wordpress/blob/master/centos8/Dockerfile) (We have finished support for CentOS 8.)
- [`centos7 (Ghostscript is not available on CentOS7)`](https://github.com/takeyamajp/docker-wordpress/blob/master/centos7/Dockerfile)

## Image summary
    FROM rockylinux:9  
    MAINTAINER "Hiroki Takeyama"
    
    ENV TIMEZONE Asia/Tokyo
    
    ENV HOSTNAME www.example.com  
    ENV FORCE_SSL true  
    ENV GZIP_COMPRESSION true
    
    ENV BASIC_AUTH false  
    ENV BASIC_AUTH_USER user  
    ENV BASIC_AUTH_PASSWORD password
    
    ENV HTTPD_SERVER_ADMIN root@localhost  
    ENV HTTPD_LOG true  
    ENV HTTPD_LOG_LEVEL warn  
    ENV HTTPD_PHP_ERROR_LOG true
    
    ENV WORDPRESS_DB_HOST mysql  
    ENV WORDPRESS_DB_NAME db  
    ENV WORDPRESS_DB_USER user  
    ENV WORDPRESS_DB_PASSWORD password  
    ENV WORDPRESS_TABLE_PREFIX wp_  
    ENV WORDPRESS_DEBUG false  
    ENV WORDPRESS_CONFIG_EXTRA param1,param2  
    ENV WORDPRESS_CONFIG_EXTRA_VALUE \'string\',true
    
    # WordPress  
    VOLUME /wordpress  
    # SSL Certificates  
    VOLUME /ssl_certs
    
    EXPOSE 80  
    EXPOSE 443

## How to use
This container is supposed to be used as a backend of a reverse proxy server.  
However, it can be simply used without the reverse proxy server.

Example `docker-compose.yml`:

    version: '3.1'  
    services:  
      wordpress:  
        image: takeyamajp/wordpress  
        ports:  
          - "8080:80"  
        environment:  
          FORCE_SSL: "false"  
      mysql:  
        image: takeyamajp/mysql  

Run `docker-compose up -d`, wait for it to initialize completely. (It takes several minutes.)  
Then, access it via `http://localhost:8080` or `http://host-ip:8080` in your browser.

## Time zone
You can use any time zone such as America/Chicago that can be used in Rocky Linux.  

See below for zones.  
https://www.unicode.org/cldr/charts/latest/verify/zones/en.html

## Force SSL
If `FORCE_SSL` is true, the URL will be redirected automatically from HTTP to HTTPS protocol.

## GZIP Compression
The `GZIP_COMPRESSION` option will save bandwidth and increase browsing speed.  
Normally, It is not necessary to be changed.

## Basic Authentication
Set `BASIC_AUTH` true if you want to use Basic Authentication.  
When `FORCE_SSL` is true, it will be used after the protocol is redirected to HTTPS.
