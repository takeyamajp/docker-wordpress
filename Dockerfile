FROM centos:centos7
MAINTAINER "Hiroki Takeyama"

# httpd (ius for CentOS7)
RUN yum -y install system-logos openssl mailcap; \
    yum -y install "https://centos7.iuscommunity.org/ius-release.rpm"; \
    yum -y install --disablerepo=base,extras,updates --enablerepo=ius httpd mod_ssl; \
    sed -i 's/DocumentRoot "\/var\/www\/html"/DocumentRoot "\/wordpress"/1' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/AllowOverride None/AllowOverride All/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/wordpress">/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*CustomLog .*/CustomLog \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^ErrorLog .*/ErrorLog \/dev\/stderr/1' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*CustomLog .*/CustomLog \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/1' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^ErrorLog .*/ErrorLog \/dev\/stderr/1' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\s*"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\"%r\\" %b"//1' /etc/httpd/conf.d/ssl.conf; \
    echo 'ServerName ${HOSTNAME}' >> /etc/httpd/conf.d/additional.conf; \
    rm -f /etc/httpd/conf.modules.d/00-proxy.conf; \
    rm -f /usr/sbin/suexec; \
    yum clean all;

# PHP (remi for CentOS7)
RUN yum -y install epel-release; \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm; \
    yum -y install --disablerepo=ius --enablerepo=remi,remi-php72 php php-mbstring php-gd php-curl php-xml php-mysqlnd php-opcache php-pecl-apcu; \
    sed -i 's/^;error_log .*/error_log = \/dev\/stderr/1' /etc/php.ini; \
    yum clean all;

# WordPress
RUN mkdir /wordpress; \
    yum -y install --disablerepo=ius wget; yum clean all; \
    wget https://wordpress.org/latest.tar.gz -P /usr/src; \
    yum clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'rm -f /etc/localtime'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'ESC_TIMEZONE=`echo ${TIMEZONE} | sed "s/\//\\\\\\\\\//g"`'; \
    echo 'sed -i "s/^;*date\.timezone =.*/date\.timezone =${ESC_TIMEZONE}/1" /etc/php.ini'; \
    echo 'sed -i "s/^LogLevel .*/LogLevel ${HTTPD_LOG_LEVEL}/1" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^LogLevel .*/LogLevel ${HTTPD_LOG_LEVEL}/1" /etc/httpd/conf.d/ssl.conf'; \
    echo 'sed -i "s/^\(CustomLog .*\)/#\1/1" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^\(ErrorLog .*\)/#\1/1" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^\(CustomLog .*\)/#\1/1" /etc/httpd/conf.d/ssl.conf'; \
    echo 'sed -i "s/^\(ErrorLog .*\)/#\1/1" /etc/httpd/conf.d/ssl.conf'; \
    echo 'if [ ${HTTPD_LOGGING,,} = "true" ]; then'; \
    echo '  sed -i "s/^#\(CustomLog .*\)/\1/1" /etc/httpd/conf/httpd.conf'; \
    echo '  sed -i "s/^#\(ErrorLog .*\)/\1/1" /etc/httpd/conf/httpd.conf'; \
    echo '  sed -i "s/^#\(CustomLog .*\)/\1/1" /etc/httpd/conf.d/ssl.conf'; \
    echo '  sed -i "s/^#\(ErrorLog .*\)/\1/1" /etc/httpd/conf.d/ssl.conf'; \
    echo 'fi'; \
    echo 'if [ -z "$(ls /wordpress)" ]; then'; \
    echo '  tar -xzf /usr/src/latest.tar.gz -C /'; \
    echo 'fi'; \
    echo 'if [ -e /wordpress/.htaccess ]; then'; \
    echo '  sed -i '\''/^# BEGIN REQUIRE SSL$/,/^# END REQUIRE SSL$/d'\'' /wordpress/.htaccess'; \
    echo '  sed -i '\''/^# BEGIN ENABLE GZIP COMPRESSION$/,/^# END ENABLE GZIP COMPRESSION$/d'\'' /wordpress/.htaccess'; \
    echo 'fi'; \
    echo 'if [ ${REQUIRE_SSL,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "# BEGIN REQUIRE SSL"'; \
    echo '  echo "<IfModule mod_rewrite.c>"'; \
    echo '  echo "  RewriteEngine On"'; \
    echo '  echo "  RewriteCond %{HTTPS} off"'; \
    echo '  echo "  RewriteCond %{HTTP:X-Forwarded-Proto} !https [NC]"'; \
    echo '  echo "  RewriteRule ^.*$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "# END REQUIRE SSL"'; \
    echo '  } > /wordpress/htaccess'; \
    echo '  if [ -e /wordpress/.htaccess ]; then'; \
    echo '    cat /wordpress/.htaccess >> /wordpress/htaccess'; \
    echo '  fi'; \
    echo '  mv -f /wordpress/htaccess /wordpress/.htaccess'; \
    echo 'fi'; \
    echo 'if [ ${ENABLE_GZIP_COMPRESSION,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "# BEGIN ENABLE GZIP COMPRESSION"'; \
    echo '  echo "<IfModule mod_deflate.c>"'; \
    echo '  echo "<IfModule mod_filter.c>"'; \
    echo '  echo "  SetOutputFilter DEFLATE"'; \
    echo '  echo "  SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "# END ENABLE GZIP COMPRESSION"'; \
    echo '  } > /wordpress/htaccess'; \
    echo '  if [ -e /wordpress/.htaccess ]; then'; \
    echo '    cat /wordpress/.htaccess >> /wordpress/htaccess'; \
    echo '  fi'; \
    echo '  mv -f /wordpress/htaccess /wordpress/.htaccess'; \
    echo 'fi'; \
    echo 'if [ -e /wordpress/.htpasswd ]; then'; \
    echo '  rm -f /etc/httpd/conf.d/basicAuth.conf'; \
    echo '  rm -f /wordpress/.htpasswd'; \
    echo 'fi'; \
    echo 'if [ ${REQUIRE_BASIC_AUTH,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "<Directory /wordpress/>"'; \
    echo '  echo "  AuthType Basic"'; \
    echo '  echo "  AuthName '\''Basic Authentication'\''"'; \
    echo '  echo "  AuthUserFile /wordpress/.htpasswd"'; \
    echo '  echo "  Require valid-user"'; \
    echo '  echo "</Directory>"'; \
    echo '  } > /etc/httpd/conf.d/basicAuth.conf'; \
    echo '  htpasswd -bmc /wordpress/.htpasswd ${BASIC_AUTH_USER} ${BASIC_AUTH_PASSWORD} &>/dev/null'; \
    echo 'fi'; \
    echo 'chown -R apache:apache /wordpress'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;
ENTRYPOINT ["entrypoint.sh"]

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

CMD ["httpd", "-DFOREGROUND"]
