FROM centos:centos8
MAINTAINER "Hiroki Takeyama"

# httpd (ius for CentOS7)
RUN yum -y install system-logos openssl mailcap; \
    yum -y install "https://centos7.iuscommunity.org/ius-release.rpm"; \
    yum -y install --disablerepo=base,extras,updates --enablerepo=ius httpd mod_ssl; \
    openssl genrsa -aes128 -passout pass:dummy -out "/etc/pki/tls/private/localhost.pass.key" 2048; \
    openssl rsa -passin pass:dummy -in "/etc/pki/tls/private/localhost.pass.key" -out "/etc/pki/tls/private/localhost.key"; \
    rm -f "/etc/pki/tls/private/localhost.pass.key"; \
    sed -i 's/^#\(ServerName\) .*/\1 ${HOSTNAME}/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(DocumentRoot\) "\/var\/www\/html"/\1 "\/wordpress"/' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/\(AllowOverride\) None/\1 All/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(<Directory\) "\/var\/www\/html">/\1 "\/wordpress">/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*\(CustomLog\) .*/\1 \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\(ErrorLog\) .*/\1 \/dev\/stderr/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*\(CustomLog\) .*/\1 \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\(ErrorLog\) .*/\1 \/dev\/stderr/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\s*"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\"%r\\" %b"//' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\(LoadModule http2_module .*\)/#\1/' /etc/httpd/conf.modules.d/00-base.conf; \
    rm -f /etc/httpd/conf.modules.d/00-proxy.conf; \
    rm -f /usr/sbin/suexec; \
    yum clean all;

# PHP (remi for CentOS7)
RUN yum -y install epel-release; \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm; \
    yum -y install --disablerepo=ius --enablerepo=remi,remi-php72 php php-mbstring php-gd php-curl php-xml php-mysqlnd php-opcache php-pecl-apcu; \
    sed -i 's/^;\(error_log\) .*/\1 = \/dev\/stderr/' /etc/php.ini; \
    yum clean all;

# WordPress
RUN mkdir /wordpress; \
    yum -y install --disablerepo=ius wget; \
    wget https://wordpress.org/latest.tar.gz -P /usr/src; \
    yum clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'rm -f /etc/localtime'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'ESC_TIMEZONE=`echo ${TIMEZONE} | sed "s/\//\\\\\\\\\//g"`'; \
    echo 'sed -i "s/^;\?\(date\.timezone\) =.*/\1 =${ESC_TIMEZONE}/" /etc/php.ini'; \
    echo 'openssl req -new -key "/etc/pki/tls/private/localhost.key" -subj "/CN=${HOSTNAME}" -out "/etc/pki/tls/certs/localhost.csr"'; \
    echo 'openssl x509 -req -days 36500 -in "/etc/pki/tls/certs/localhost.csr" -signkey "/etc/pki/tls/private/localhost.key" -out "/etc/pki/tls/certs/localhost.crt" &>/dev/null'; \
    echo 'if [ -n "${HTTPD_SERVER_ADMIN}" ]; then'; \
    echo '  sed -i "s/^\(ServerAdmin\) .*/\1 ${HTTPD_SERVER_ADMIN}/" /etc/httpd/conf/httpd.conf'; \
    echo 'fi'; \
    echo 'sed -i "s/^\(LogLevel\) .*/\1 ${HTTPD_LOG_LEVEL}/" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^\(LogLevel\) .*/\1 ${HTTPD_LOG_LEVEL}/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'sed -i "s/^\(CustomLog .*\)/#\1/" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^\(ErrorLog .*\)/#\1/" /etc/httpd/conf/httpd.conf'; \
    echo 'sed -i "s/^\(CustomLog .*\)/#\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'sed -i "s/^\(ErrorLog .*\)/#\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'if [ ${HTTPD_LOG,,} = "true" ]; then'; \
    echo '  sed -i "s/^#\(CustomLog .*\)/\1/" /etc/httpd/conf/httpd.conf'; \
    echo '  sed -i "s/^#\(ErrorLog .*\)/\1/" /etc/httpd/conf/httpd.conf'; \
    echo '  sed -i "s/^#\(CustomLog .*\)/\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo '  sed -i "s/^#\(ErrorLog .*\)/\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'fi'; \
    echo 'sed -i "s/^\(log_errors\) .*/\1 = Off/" /etc/php.ini'; \
    echo 'if [ ${HTTPD_PHP_ERROR_LOG,,} = "true" ]; then'; \
    echo '  sed -i "s/^\(log_errors\) .*/\1 = On/" /etc/php.ini'; \
    echo 'fi'; \
    echo 'if [ -z "$(ls /wordpress)" ]; then'; \
    echo '  tar -xzf /usr/src/latest.tar.gz -C /'; \
    echo 'fi'; \
    echo 'if [ -e /wordpress/.htaccess ]; then'; \
    echo '  sed -i '\''/^# BEGIN REQUIRE SSL$/,/^# END REQUIRE SSL$/d'\'' /wordpress/.htaccess'; \
    echo '  sed -i '\''/^# BEGIN GZIP COMPRESSION$/,/^# END GZIP COMPRESSION$/d'\'' /wordpress/.htaccess'; \
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
    echo 'if [ ${GZIP_COMPRESSION,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "# BEGIN GZIP COMPRESSION"'; \
    echo '  echo "<IfModule mod_deflate.c>"'; \
    echo '  echo "<IfModule mod_filter.c>"'; \
    echo '  echo "  SetOutputFilter DEFLATE"'; \
    echo '  echo "  SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "# END GZIP COMPRESSION"'; \
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
    echo 'if [ ${BASIC_AUTH,,} = "true" ]; then'; \
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

CMD ["httpd", "-DFOREGROUND"]