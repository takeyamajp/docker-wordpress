FROM centos:centos7
MAINTAINER "Hiroki Takeyama"

# timezone
RUN rm -f /etc/localtime; \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime;

# httpd
RUN yum -y install httpd mod_ssl; yum clean all; \
    sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/wordpress"/1' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/AllowOverride None/AllowOverride All/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/wordpress">/1' /etc/httpd/conf/httpd.conf;

# prevent error AH00558 on stdout
RUN echo 'ServerName ${HOSTNAME}' >> /etc/httpd/conf.d/additional.conf

# PHP (remi for CentOS7)
RUN yum -y install epel-release; yum clean all; \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm; \
    yum -y install --enablerepo=remi,remi-php72 php php-mbstring php-curl php-mysqlnd; yum clean all; \
    sed -i 's/^;date\.timezone =$/date\.timezone=Asia\/Tokyo/1' /etc/php.ini;

# WordPress
RUN mkdir /wordpress; \
    yum -y install wget; yum clean all; \
    wget https://wordpress.org/latest.tar.gz -P /usr/src;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'if [ -z "$(ls /wordpress)" ]; then'; \
    echo '  tar -xzf /usr/src/latest.tar.gz -C /'; \
    echo 'fi'; \
    echo 'chown -R apache:apache /wordpress'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;
ENTRYPOINT ["entrypoint.sh"]

VOLUME /wordpress

EXPOSE 80
EXPOSE 443

CMD ["httpd", "-DFOREGROUND"]
