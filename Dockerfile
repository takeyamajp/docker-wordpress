FROM centos
MAINTAINER "Hiroki Takeyama"

# timezone
RUN rm -f /etc/localtime; \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime;

# httpd
RUN yum -y install httpd mod_ssl; yum clean all; \
    sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/var\/www\/html\/wordpress"/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html\/wordpress">"/1' /etc/httpd/conf/httpd.conf; \
    { \
    echo '<Directory /var/www/html/wordpress>'; \
    echo '    AllowOverride All'; \
    echo '</Directory>'; \
    } >> /etc/httpd/conf/httpd.conf;

# prevent error AH00558 on stdout
RUN echo 'ServerName ${HOSTNAME}' >> /etc/httpd/conf.d/additional.conf

# PHP
RUN yum -y install epel-release; yum clean all; \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm; \
    yum -y install --enablerepo=remi --enablerepo=remi-php72 php php-mbstring php-curl php-mysqlnd; yum clean all; \
    sed -i 's/^;date\.timezone =$/date\.timezone=Asia\/Tokyo/1' /etc/php.ini;

# WordPress
RUN yum -y install wget; yum clean all; \
    wget https://wordpress.org/latest.tar.gz -P /tmp; \
    tar -xzvf /tmp/latest.tar.gz -C /var/www/html; \
    rm /tmp/latest.tar.gz;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'chown -R apache:apache /var/www/html/wordpress'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;
ENTRYPOINT ["entrypoint.sh"]

VOLUME /var/www/html/wordpress

EXPOSE 80
EXPOSE 443

CMD ["httpd", "-DFOREGROUND"]
