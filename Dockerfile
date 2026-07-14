FROM php:8.2-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libssh2-1-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gd \
        intl \
        mysqli \
        pdo_mysql \
        soap \
        zip \
    && pecl install ssh2-1.4 \
    && docker-php-ext-enable ssh2 \
    && a2dismod mpm_prefork mpm_worker mpm_event 2>/dev/null || true \
    && a2enmod mpm_prefork \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

WORKDIR /var/www/html
COPY . /var/www/html/
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/entrypoint.sh /usr/local/bin/mirzabot-entrypoint

RUN chmod +x /usr/local/bin/mirzabot-entrypoint \
    && chown -R www-data:www-data /var/www/html

ENTRYPOINT ["mirzabot-entrypoint"]
CMD ["apache2-foreground"]
