FROM php:8.1-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libldap2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxslt-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        xml \
        mbstring \
        curl \
        zip \
        intl \
        gd \
        soap \
        bcmath \
        opcache \
        ldap \
        xsl

# Enable Apache modules
RUN a2enmod rewrite headers expires

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www/html/elgg

# Copy composer files and install dependencies first (better caching)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-progress --optimize-autoloader

# Copy Elgg source code
COPY . /var/www/html/elgg

# Create data & config directories (mount points for PVCs)
RUN mkdir -p /var/www/html/data \
    && mkdir -p /var/www/html/elgg/elgg-config

# Set permissions for runtime
RUN chown -R www-data:www-data /var/www/html/elgg /var/www/html/data \
    && chmod -R 775 /var/www/html/elgg/elgg-config /var/www/html/data

# These will be replaced by PVCs in Kubernetes
VOLUME ["/var/www/html/data", "/var/www/html/elgg/elgg-config"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
CMD ["apache2-foreground"]
