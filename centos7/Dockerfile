FROM centos:centos7
MAINTAINER "Hiroki Takeyama"

# openssl
RUN mkdir /ssl_certs; \
    yum -y install openssl; \
    sed -i '/^\[ usr_cert \]$/a subjectAltName = @alt_names' /etc/pki/tls/openssl.cnf; \
    sed -i 's/^# \(req_extensions = v3_req\)/\1/' /etc/pki/tls/openssl.cnf; \
    sed -i '/^\[ v3_req \]$/a subjectAltName = @alt_names' /etc/pki/tls/openssl.cnf; \
    echo '[alt_names]' >> /etc/pki/tls/openssl.cnf; \
    echo 'DNS.1 =' >> /etc/pki/tls/openssl.cnf; \
    mkdir -p /etc/pki/CA/newcerts; \
    yum clean all;

# httpd (ius for CentOS7)
RUN yum -y install system-logos mailcap; \
    yum -y install "https://repo.ius.io/ius-release-el7.rpm"; \
    yum -y install --disablerepo=base,extras,updates --enablerepo=ius httpd mod_ssl; \
    sed -i 's/^#\(ServerName\) .*/\1 ${HOSTNAME}/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(DocumentRoot\) "\/var\/www\/html"/\1 "\/wordpress"/' /etc/httpd/conf/httpd.conf; \
    sed -i '/^<Directory "\/var\/www\/html">$/,/^<IfModule dir_module>$/ s/\(AllowOverride\) None/\1 All/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/\(<Directory\) "\/var\/www\/html">/\1 "\/wordpress">/' /etc/httpd/conf/httpd.conf; \
    sed -i 's/^\(SSLCertificateFile\) .*/\1 \/ssl_certs\/cert.pem/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^\(SSLCertificateKeyFile\) .*/\1 \/ssl_certs\/key.pem/' /etc/httpd/conf.d/ssl.conf; \
    sed -i 's/^#\(SSLCertificateChainFile\) .*/\1 \/ssl_certs\/chain.pem/' /etc/httpd/conf.d/ssl.conf; \
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
    yum -y install --disablerepo=ius --enablerepo=remi,remi-php74 php php-mbstring php-gd php-curl php-xml php-mysqlnd php-opcache php-pecl-apcu php-pecl-imagick php-pecl-zip; \
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
    echo 'ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime'; \
    echo 'ESC_TIMEZONE=`echo ${TIMEZONE} | sed "s/\//\\\\\\\\\//g"`'; \
    echo 'sed -i "s/^;\?\(date\.timezone\) =.*/\1 =${ESC_TIMEZONE}/" /etc/php.ini'; \
    echo 'sed -i "s/^\(SSLCertificateChainFile .*\)/#\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo 'if [ ! -e /ssl_certs/cert.pem ] || [ ! -e /ssl_certs/key.pem ]; then'; \
    echo '  if [ ! -e /ssl_certs/cacert.pem ] || [ ! -e /ssl_certs/cakey.pem ]; then'; \
    echo '    openssl genrsa -out "/ssl_certs/cakey.pem" 2048 &>/dev/null'; \
    echo '    openssl req -new -key "/ssl_certs/cakey.pem" -subj "/CN=WordPress CA" -out "/ssl_certs/cacsr.pem"'; \
    echo '    openssl x509 -req -days 36500 -in "/ssl_certs/cacsr.pem" -signkey "/ssl_certs/cakey.pem" -out "/ssl_certs/cacert.pem" &>/dev/null'; \
    echo '  fi'; \
    echo '  echo "01" > /etc/pki/CA/serial'; \
    echo '  rm -f /etc/pki/CA/index.txt'; \
    echo '  touch /etc/pki/CA/index.txt'; \
    echo '  sed -i "/^\(DNS\)\|\(IP\)\.1 = .\+$/d" /etc/pki/tls/openssl.cnf'; \
    echo '  if [ -n "`echo "${HOSTNAME}" | sed -e "s/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+//g"`" ]; then'; \
    echo '    echo "DNS.1 = ${HOSTNAME}" >> /etc/pki/tls/openssl.cnf'; \
    echo '  else'; \
    echo '    echo "IP.1 = ${HOSTNAME}" >> /etc/pki/tls/openssl.cnf'; \
    echo '  fi'; \
    echo '  openssl genrsa -out "/ssl_certs/key.pem" 2048 &>/dev/null'; \
    echo '  openssl req -config /etc/pki/tls/openssl.cnf -new -key "/ssl_certs/key.pem" -subj "/CN=${HOSTNAME}" -out "/ssl_certs/csr.pem"'; \
    echo '  openssl ca -batch -policy policy_anything -config /etc/pki/tls/openssl.cnf -days 36500 -in "/ssl_certs/csr.pem" -cert "/ssl_certs/cacert.pem" -keyfile "/ssl_certs/cakey.pem" -out "/ssl_certs/cert.pem" &>/dev/null'; \
    echo '  rm -f /ssl_certs/chain.pem'; \
    echo 'else'; \
    echo '  if [ -e /ssl_certs/chain.pem ]; then'; \
    echo '    sed -i "s/^#\(SSLCertificateChainFile .*\)/\1/" /etc/httpd/conf.d/ssl.conf'; \
    echo '  fi'; \
    echo 'fi'; \
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
    echo 'sed -i "s/^\(define( *'\''DB_HOST'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_HOST}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_NAME'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_NAME}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_USER'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_USER}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_PASSWORD'\'', *'\''\).*\('\'' *);\)/\1${WORDPRESS_DB_PASSWORD}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_CHARSET'\'', *'\''\).*\('\'' *);\)/\1utf8mb4\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''DB_COLLATE'\'', *'\''\).*\('\'' *);\)/\1\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(\$table_prefix = '\''\).*\('\'';\)/\1${WORDPRESS_TABLE_PREFIX}\2/" /wordpress/wp-config.php'; \
    echo 'sed -i "s/^\(define( *'\''WP_DEBUG'\'', *\)\S*\( *);\)/\1${WORDPRESS_DEBUG}\2/" /wordpress/wp-config.php'; \
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
    echo 'if [ -e /etc/httpd/conf.d/forceSsl.conf ]; then'; \
    echo '  rm -f /etc/httpd/conf.d/forceSsl.conf'; \
    echo 'fi'; \
    echo 'if [ ${FORCE_SSL,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "<IfModule mod_rewrite.c>"'; \
    echo '  echo "  RewriteEngine On"'; \
    echo '  echo "  RewriteCond %{HTTPS} off"'; \
    echo '  echo "  RewriteCond %{HTTP:X-Forwarded-Proto} !https [NC]"'; \
    echo '  echo "  RewriteRule ^.*$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]"'; \
    echo '  echo "</IfModule>"'; \
    echo '  } > /etc/httpd/conf.d/forceSsl.conf'; \
    echo 'fi'; \
    echo 'if [ -e /etc/httpd/conf.d/gzipCompression.conf ]; then'; \
    echo '  rm -f /etc/httpd/conf.d/gzipCompression.conf'; \
    echo 'fi'; \
    echo 'if [ ${GZIP_COMPRESSION,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "<IfModule mod_deflate.c>"'; \
    echo '  echo "<IfModule mod_filter.c>"'; \
    echo '  echo "  SetOutputFilter DEFLATE"'; \
    echo '  echo "  SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary"'; \
    echo '  echo "</IfModule>"'; \
    echo '  echo "</IfModule>"'; \
    echo '  } > /etc/httpd/conf.d/gzipCompression.conf'; \
    echo 'fi'; \
    echo 'if [ -e /etc/httpd/conf.d/basicAuth.conf ]; then'; \
    echo '  rm -f /etc/httpd/conf.d/basicAuth.conf'; \
    echo '  rm -f /etc/httpd/conf.d/.htpasswd'; \
    echo 'fi'; \
    echo 'if [ ${BASIC_AUTH,,} = "true" ]; then'; \
    echo '  {'; \
    echo '  echo "<Directory /wordpress/>"'; \
    echo '  if [ ${FORCE_SSL,,} = "true" ]; then'; \
    echo '    echo "<If \"%{HTTPS} = '\''on'\''\">"'; \
    echo '  fi'; \
    echo '  echo "  AuthType Basic"'; \
    echo '  echo "  AuthName '\''Basic Authentication'\''"'; \
    echo '  echo "  AuthUserFile /etc/httpd/conf.d/.htpasswd"'; \
    echo '  echo "  Require valid-user"'; \
    echo '  if [ ${FORCE_SSL,,} = "true" ]; then'; \
    echo '    echo "</If>"'; \
    echo '  fi'; \
    echo '  echo "</Directory>"'; \
    echo '  } > /etc/httpd/conf.d/basicAuth.conf'; \
    echo '  htpasswd -bmc /etc/httpd/conf.d/.htpasswd ${BASIC_AUTH_USER} ${BASIC_AUTH_PASSWORD} &>/dev/null'; \
    echo 'fi'; \
    echo 'chown -R apache:apache /wordpress'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;

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

ENTRYPOINT ["entrypoint.sh"]
CMD ["httpd", "-DFOREGROUND"]
