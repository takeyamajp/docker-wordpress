# takeyamajp/wordpress
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/wordpress.svg?style=flat-square)](https://hub.docker.com/r/takeyamajp/wordpress/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/wordpress.svg?style=flat-square)](https://hub.docker.com/r/takeyamajp/wordpress/)

FROM centos:centos7  
MAINTAINER "Hiroki Takeyama"

ENV TIMEZONE Asia/Tokyo

ENV REQUIRE_SSL true  
ENV ENABLE_GZIP_COMPRESSION true

ENV REQUIRE_BASIC_AUTH false  
ENV BASIC_AUTH_USER user  
ENV BASIC_AUTH_PASSWORD user

VOLUME /wordpress

EXPOSE 80  
EXPOSE 443
