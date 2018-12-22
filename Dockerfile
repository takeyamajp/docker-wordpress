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
RUN echo 'ServerName ${HOSTNAME}' >> /etc/httpd/conf.d/additional.conf;

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
    echo 'if [ -e /wordpress/.htaccess ]; then'; \
    echo '  sed -i '\''/^# BEGIN REQUIRE SSL$/,/^# END REQUIRE SSL$/d'\'' /wordpress/.htaccess'; \
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
    echo 'if [ -e /wordpress/wp-config.php ]; then'; \
    echo '  cp /wordpress/wp-config-sample.php /wordpress/wp-config.php'; \
    echo 'fi'; \
    echo 'uniqueKeys=('; \
    echo '  AUTH_KEY'; \
    echo '  SECURE_AUTH_KEY'; \
    echo '  LOGGED_IN_KEY'; \
    echo '  NONCE_KEY'; \
    echo '  AUTH_SALT'; \
    echo '  SECURE_AUTH_SALT'; \
    echo '  LOGGED_IN_SALT'; \
    echo '  NONCE_SALT'; \
    echo ')'; \
    echo 'sed_escape_lhs() {'; \
    echo '  echo "$@" | sed -e '\''s/[]\/$*.^|[]/\\&/g'\'''; \
    echo '}'; \
    echo 'sed_escape_rhs() {'; \
    echo '  echo "$@" | sed -e '\''s/[\/&]/\\&/g'\'''; \
    echo '}'; \
    echo 'php_escape() {'; \
    echo '  local escaped="$(php -r '\''var_export(('\''"$2"'\'') $argv[1]);'\'' -- "$1")"'; \
    echo '  if [ "$2" = '\''string'\'' ] && [ "${escaped:0:1}" = "'\''" ]; then'; \
    echo '  escaped="${escaped//$'\''\n'\''/"'\'' + \"\\n\" + '\''"}"'; \
    echo '  fi'; \
    echo '  echo "$escaped"'; \
    echo '}'; \
    echo 'set_config() {'; \
    echo '  key="$1"'; \
    echo '  value="$2"'; \
    echo '  var_type="${3:-string}"'; \
    echo '  start="(['\''\"])$(sed_escape_lhs "$key")\2\s*,"'; \
    echo '  end="\);"'; \
    echo '  if [ "${key:0:1}" = '\''$'\'' ]; then'; \
    echo '    start="^(\s*)$(sed_escape_lhs "$key")\s*="'; \
    echo '    end=";"'; \
    echo '  fi'; \
    echo '  sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" /wordpress/wp-config.php'; \
    echo '}'; \
    echo 'set_config '\''DB_HOST'\'' "$WORDPRESS_DB_HOST"'; \
    echo 'set_config '\''DB_USER'\'' "$WORDPRESS_DB_USER"'; \
    echo 'set_config '\''DB_PASSWORD'\'' "$WORDPRESS_DB_PASSWORD"'; \
    echo 'set_config '\''DB_NAME'\'' "$WORDPRESS_DB_NAME"'; \
    echo 'set_config '\''DB_CHARSET'\'' "$WORDPRESS_DB_CHARSET"'; \
    echo 'set_config '\''DB_COLLATE'\'' "$WORDPRESS_DB_COLLATE"'; \
    echo 'for uniqueKey in "${uniqueKeys[@]}"; do'; \
    echo '  currentValue="$(sed -rn -e "s/define\((([\'\''\"])$uniqueKey\2\s*,\s*)(['\''\"])(.*)\3\);/\4/p" /wordpress/wp-config.php)"'; \
    echo '  if [ "$currentValue" = '\''put your unique phrase here'\'' ]; then'; \
    echo '    set_config "$uniqueKey" "$(head -c1m /dev/urandom | sha1sum | cut -d'\'' '\'' -f1)"'; \
    echo '  fi'; \
    echo 'done'; \
    echo 'chown -R apache:apache /wordpress'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh; \
    chmod +x /usr/local/bin/entrypoint.sh;
ENTRYPOINT ["entrypoint.sh"]

ENV REQUIRE_SSL true

ENV WORDPRESS_DB_HOST mysql
ENV WORDPRESS_DB_USER user
ENV WORDPRESS_DB_PASSWORD user
ENV WORDPRESS_DB_NAME db
ENV WORDPRESS_DB_CHARSET utf8mb4
ENV WORDPRESS_DB_COLLATE

VOLUME /wordpress

EXPOSE 80
EXPOSE 443

CMD ["httpd", "-DFOREGROUND"]
