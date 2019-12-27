FROM centos:centos8
MAINTAINER "Hiroki Takeyama"

# certificate
RUN mkdir /cert; \
    dnf -y install openssl; \
    openssl genrsa -aes256 -passout pass:dummy -out "/cert/key.pass.pem" 2048; \
    openssl rsa -passin pass:dummy -in "/cert/key.pass.pem" -out "/cert/key.pem"; \
    rm -f /cert/key.pass.pem; \
    dnf clean all;

# httpd
RUN dnf -y install httpd mod_ssl; \
    sed -i 's/^#\(ServerName\) .*/\1 ${HOSTNAME}/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(DocumentRoot\) "\/var\/www\/html"/\1 "\/wordpress"/' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/\(AllowOverride\) None/\1 All/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(<Directory\) "\/var\/www\/html">/\1 "\/wordpress">/' /etc/httpd/conf/httpd.conf; \
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
    echo 'priority=3'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/fd/2'; \
    echo 'stderr_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/httpd.ini; \
    { \
    echo '[program:php-fpm]'; \
    echo 'command=/usr/sbin/php-fpm --nodaemonize'; \
    echo 'priority=2'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    echo 'stderr_logfile=/dev/fd/2'; \
    echo 'stderr_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/php-fpm.ini; \
    { \
    echo '[program:tail]'; \
    echo 'command=/usr/bin/tail -F /var/log/php-fpm/www-error.log'; \
    echo 'priority=1'; \
    echo 'stdout_logfile=/dev/fd/1'; \
    echo 'stdout_logfile_maxbytes=0'; \
    } > /etc/supervisord.d/tail.ini; \
    dnf clean all;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'rm -f /etc/localtime'; \
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'ESC_TIMEZONE=`echo ${TIMEZONE} | sed "s/\//\\\\\\\\\//g"`'; \
    echo 'sed -i "s/^;\?\(date\.timezone\) =.*/\1 =${ESC_TIMEZONE}/" /etc/php.ini'; \
    echo 'rm -f /var/log/php-fpm/www-error.log'; \
    echo 'touch /var/log/php-fpm/www-error.log'; \
    echo 'openssl req -new -sha384 -key "/cert/key.pem" -subj "/CN=${HOSTNAME}" -out "/cert/csr.pem"'; \
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
    echo 'sed -i "s/^\(php_admin_flag\[log_errors\]\) = .*/\1 = off/" /etc/php-fpm.d/www.conf'; \
    echo 'if [ ${HTTPD_PHP_ERROR_LOG,,} = "true" ]; then'; \
    echo '  sed -i "s/^\(php_admin_flag\[log_errors\]\) = .*/\1 = on/" /etc/php-fpm.d/www.conf'; \
    echo 'fi'; \
    echo 'if [ -z "$(ls /wordpress)" ]; then'; \
    echo '  tar -xzf /usr/src/latest.tar.gz -C /'; \
    echo 'fi'; \
    echo 'if [ ! -e /wordpress/wp-config.php ]; then'; \
    echo '  cp /wordpress/wp-config-sample.php /wordpress/wp-config.php'; \
    echo '  CHARS='\''abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^*()-_ []{}<>~`+=,.;:?|'\'';'; \
    echo '  for i in $(seq 8); do for j in $(seq 64); do KEYS[$(($i - 1))]+=${CHARS:$(($RANDOM % ${#CHARS})):1}; done; done;'; \
    echo '  sed -i "s/^\(define( *'\''AUTH_KEY'\'', *'\''\).*\('\'' *);\)/\1${KEYS[0]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''SECURE_AUTH_KEY'\'', *'\''\).*\('\'' *);\)/\1${KEYS[1]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''LOGGED_IN_KEY'\'', *'\''\).*\('\'' *);\)/\1${KEYS[2]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''NONCE_KEY'\'', *'\''\).*\('\'' *);\)/\1${KEYS[3]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''AUTH_SALT'\'', *'\''\).*\('\'' *);\)/\1${KEYS[4]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''SECURE_AUTH_SALT'\'', *'\''\).*\('\'' *);\)/\1${KEYS[5]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''LOGGED_IN_SALT'\'', *'\''\).*\('\'' *);\)/\1${KEYS[6]}\2/" /wordpress/wp-config.php'; \
    echo '  sed -i "s/^\(define( *'\''NONCE_SALT'\'', *'\''\).*\('\'' *);\)/\1${KEYS[7]}\2/" /wordpress/wp-config.php'; \
    echo 'fi'; \
    echo 'sed -i "s/^\(define( *'\''DB_NAME'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_NAME}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_USER'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_USER}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_PASSWORD'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_PASSWORD}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_HOST'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_HOST}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_CHARSET'\'', *'\''\).*\('\'' *);\)/\1utf8mb4\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_COLLATE'\'', *'\''\).*\('\'' *);\)/\1\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(\$table_prefix = '\''\).*\('\'';\)/\1${WORDPRESS_TABLE_PREFIX}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''WP_DEBUG'\'', *\).*\( *);\)/\1${WORDPRESS_DEBUG}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i '\''/^\/\/ BEGIN CONFIG EXTRA\r*$/,/^\/\/ END CONFIG EXTRA\r*$/d'\'' /wordpress/wp-config.php'; \
    echo 'ARRAY_PARAM=(`echo ${WORDPRESS_CONFIG_EXTRA} | tr "," " "`)'; \
    echo 'ARRAY_VALUE=(`echo ${WORDPRESS_CONFIG_EXTRA_VALUE} | tr "," " "`)'; \
    echo 'if [ ${#ARRAY_PARAM[@]} -gt 0 -a ${#ARRAY_VALUE[@]} -gt 0 -a ${#ARRAY_PARAM[@]} -eq ${#ARRAY_VALUE[@]} ]; then'; \
    echo '  sed -i '\''/^<?php\r*$/a \/\/ BEGIN CONFIG EXTRA\n\/\/ END CONFIG EXTRA'\'' /wordpress/wp-config.php'; \
    echo '  INDEX=0'; \
    echo '  for e in ${ARRAY_PARAM[@]}; do'; \
    echo '    sed -i "/^\/\/ END CONFIG EXTRA\r*$/i define('\''${ARRAY_PARAM[${INDEX}]}'\'', ${ARRAY_VALUE[${INDEX}]});" /wordpress/wp-config.php'; \
    echo '    ((INDEX+=1))'; \
    echo '  done'; \
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
ENV BASIC_AUTH_PASSWORD password

ENV HTTPD_SERVER_ADMIN root@localhost
ENV HTTPD_LOG true
ENV HTTPD_LOG_LEVEL warn
ENV HTTPD_PHP_ERROR_LOG true

ENV WORDPRESS_DB_NAME db
ENV WORDPRESS_DB_USER user
ENV WORDPRESS_DB_PASSWORD password
ENV WORDPRESS_DB_HOST mysql
ENV WORDPRESS_TABLE_PREFIX wp_
ENV WORDPRESS_DEBUG false
ENV WORDPRESS_CONFIG_EXTRA param1,param2
ENV WORDPRESS_CONFIG_EXTRA_VALUE \'string\',true

VOLUME /wordpress

EXPOSE 80
EXPOSE 443

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
