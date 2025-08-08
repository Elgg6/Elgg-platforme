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

# Create necessary directories
RUN mkdir -p /var/www/html/elgg/data && \
    mkdir -p /var/www/html/elgg/elgg-config && \
    chown -R www-data:www-data /var/www/html/elgg

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy only necessary files for initial build
COPY composer.json composer.lock /var/www/html/elgg/
COPY .htaccess /var/www/html/elgg/

# Install dependencies
RUN cd /var/www/html/elgg && \
    composer install --no-dev --no-scripts --no-progress --optimize-autoloader

# Copy remaining application files
COPY . /var/www/html/elgg

# Set permissions
RUN chown -R www-data:www-data /var/www/html/elgg && \
    find /var/www/html/elgg -type d -exec chmod 755 {} \; && \
    find /var/www/html/elgg -type f -exec chmod 644 {} \; && \
    chmod -R 775 /var/www/html/elgg/data /var/www/html/elgg/elgg-config

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
CMD ["apache2-foreground"]
