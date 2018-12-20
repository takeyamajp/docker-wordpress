FROM centos:centos7  
MAINTAINER "Hiroki Takeyama"

ENV REQUIRE_SSL true

VOLUME /wordpress

EXPOSE 80  
EXPOSE 443
