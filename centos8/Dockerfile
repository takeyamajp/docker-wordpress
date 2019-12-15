FROM centos:centos8
MAINTAINER "Hiroki Takeyama"

# certificate
RUN mkdir /cert; \
    dnf -y install openssl; \
    openssl genrsa -aes128 -passout pass:dummy -out "/cert/key.pass.pem" 2048; \
    openssl rsa -passin pass:dummy -in "/cert/key.pass.pem" -out "/cert/key.pem"; \
    rm -f /cert/key.pass.pem; \
    dnf clean all;

# httpd
RUN dnf -y install httpd mod_ssl; \
    sed -i 's/^#\(ServerName\) .*/\1 ${HOSTNAME}/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(DocumentRoot\) "\/var\/www\/html"/\1 "\wordpress"/' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/\(AllowOverride\) None/\1 All/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(<Directory\) "\/var\/www\/html">/\1 "\wordpress">/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*\(CustomLog\) .*/\1 \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\(ErrorLog\) .*/\1 \/dev\/stderr/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\s*\(CustomLog\) .*/\1 \/dev\/stdout "%{X-Forwarded-For}i %h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i\\" \\"%{User-Agent}i\\" %I %O"/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\(ErrorLog\) .*/\1 \/dev\/stderr/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\s*"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\"%r\\" %b"//' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\(LoadModule lbmethod_heartbeat_module .*\)/#\1/' /etc/httpd/conf.modules.d/00-proxy.conf; \
    rm -f /usr/sbin/suexec; \
    dnf clean all;

# PHP (remi for CentOS8)
RUN mkdir /run/php-fpm; \
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
    dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm; \
    dnf -y module enable php:remi-7.4; \
    dnf -y install php php-mbstring php-gd php-curl php-xml php-mysqlnd php-opcache php-pecl-apcu; \
    sed -i 's/^;\(error_log\) .*/\1 = \/dev\/stderr/' /etc/php.ini; \
    sed -i 's/^;\(listen.owner\) .*/\1 = apache/' /etc/php-fpm.d/www.conf; \
    sed -i 's/^;\(listen.group\) .*/\1 = apache/' /etc/php-fpm.d/www.conf; \
    sed -i 's/^\(listen.acl_users .*\)/;\1/' /etc/php-fpm.d/www.conf; \
    dnf clean all;

# WordPress
RUN mkdir /wordpress; \
    dnf -y install wget; \
    wget https://wordpress.org/latest.tar.gz -P /usr/src; \
    dnf clean all;

# supervisor
RUN mkdir /run/supervisor; \
    dnf -y install supervisor; \
    sed -i 's/^\(nodaemon\)=false/\1=true/' /etc/supervisord.conf; \
    sed -i 's/^;\(user\)=chrism/\1=root/' /etc/supervisord.conf; \
    sed -i '/^\[unix_http_server\]$/a username=dummy\npassword=dummy' /etc/supervisord.conf; \
    sed -i '/^\[supervisorctl\]$/a username=dummy\npassword=dummy' /etc/supervisord.conf; \
    { \
    echo '[program:httpd]'; \
    echo 'command=/usr/sbin/httpd -DFOREGROUND'; \
    echo 'priority=2'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/fd/2'; \
    echo 'stderr_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/httpd.ini; \
    { \
    echo '[program:php-fpm]'; \
    echo 'command=/usr/sbin/php-fpm --nodaemonize'; \
    echo 'priority=1'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/fd/2'; \
    echo 'stderr_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/php-fpm.ini; \
    dnf clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'rm -f /etc/localtime'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'ESC_TIMEZONE=`echo ${TIMEZONE} | sed "s/\//\\\\\\\\\//g"`'; \
    echo 'sed -i "s/^;\?\(date\.timezone\) =.*/\1 =${ESC_TIMEZONE}/" /etc/php.ini'; \
    echo 'openssl req -new -key "/cert/key.pem" -subj "/CN=${HOSTNAME}" -out "/cert/csr.pem"'; \
    echo 'openssl x509 -req -days 36500 -in "/cert/csr.pem" -signkey "/cert/key.pem" -out "/cert/cert.pem" &>/dev/null'; \
    echo 'sed -i "s/^\(SSLCertificateFile\) .*/\1 \/cert\/cert.pem/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'sed -i "s/^\(SSLCertificateKeyFile\) .*/\1 \/cert\/key.pem/" /etc/httpd/conf.d/ssl.conf'; \
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

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
