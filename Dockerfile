# FROM php:8.1-apache

# # Install system dependencies
# RUN apt-get update && apt-get install -y \
#     git \
#     unzip \
#     curl \
#     libzip-dev \
#     libonig-dev \
#     libxml2-dev \
#     libldap2-dev \
#     libpng-dev \
#     libjpeg-dev \
#     libfreetype6-dev \
#     libicu-dev \
#     libcurl4-openssl-dev \
#     libssl-dev \
#     libxslt-dev \
#     && rm -rf /var/lib/apt/lists/*

# # Configure and install PHP extensions
# RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
#     docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
#     docker-php-ext-install -j$(nproc) \
#         mysqli \
#         pdo_mysql \
#         xml \
#         mbstring \
#         curl \
#         zip \
#         intl \
#         gd \
#         soap \
#         bcmath \
#         opcache \
#         ldap \
#         xsl

# # Enable Apache modules
# RUN a2enmod rewrite headers expires

# # Install Composer
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# # Set working directory
# WORKDIR /var/www/html/elgg

# # Copy composer files and install dependencies first (better caching)
# COPY composer.json composer.lock ./
# RUN composer install --no-dev --no-scripts --no-progress --optimize-autoloader

# # Copy Elgg source code
# COPY . /var/www/html/elgg

# # Create data & config directories (mount points for PVCs)
# RUN mkdir -p /var/www/html/data \
#     && mkdir -p /var/www/html/elgg/elgg-config

# # Set permissions for runtime
# RUN chown -R www-data:www-data /var/www/html/elgg /var/www/html/data \
#     && chmod -R 775 /var/www/html/elgg/elgg-config /var/www/html/data

# # These will be replaced by PVCs in Kubernetes
# VOLUME ["/var/www/html/data", "/var/www/html/elgg/elgg-config"]

# # Health check
# HEALTHCHECK --interval=30s --timeout=3s \
#     CMD curl -f http://localhost/ || exit 1

# EXPOSE 80
# CMD ["apache2-foreground"]
######################################################################################################################

# FROM php:8.1-apache

# # Install system dependencies
# RUN apt-get update && apt-get install -y \
#     git \
#     unzip \
#     curl \
#     libzip-dev \
#     libonig-dev \
#     libxml2-dev \
#     libldap2-dev \
#     libpng-dev \
#     libjpeg-dev \
#     libfreetype6-dev \
#     libicu-dev \
#     libcurl4-openssl-dev \
#     libssl-dev \
#     libxslt-dev \
#     && rm -rf /var/lib/apt/lists/*

# # Configure and install PHP extensions
# RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
#     docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
#     docker-php-ext-install -j$(nproc) \
#         mysqli \
#         pdo_mysql \
#         xml \
#         mbstring \
#         curl \
#         zip \
#         intl \
#         gd \
#         soap \
#         bcmath \
#         opcache \
#         ldap \
#         xsl

# # Enable Apache modules and configure
# RUN a2enmod rewrite headers expires && \
#     echo "<VirtualHost *:80>\n\
#         DocumentRoot /var/www/html/elgg\n\
#         <Directory /var/www/html/elgg>\n\
#             Options -Indexes +FollowSymLinks\n\
#             AllowOverride All\n\
#             Require all granted\n\
#         </Directory>\n\
#         ErrorLog \${APACHE_LOG_DIR}/error.log\n\
#         CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
#     </VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# # Install Composer
# RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# # Set working directory
# WORKDIR /var/www/html/elgg

# # Copy composer files and install dependencies first (better caching)
# COPY composer.json composer.lock ./
# RUN composer install --no-dev --no-scripts --no-progress --optimize-autoloader

# # Copy only necessary files (exclude development files)
# COPY . .

# # Create directories that will be mounted as volumes
# RUN mkdir -p /var/www/html/data \
#     && mkdir -p /var/www/html/elgg/elgg-config \
#     && touch /var/www/html/elgg/elgg-config/settings.php

# # Set permissions
# RUN chown -R www-data:www-data /var/www/html \
#     && find /var/www/html -type d -exec chmod 755 {} \; \
#     && find /var/www/html -type f -exec chmod 644 {} \; \
#     && chmod -R 775 /var/www/html/elgg/elgg-config /var/www/html/data

# # Clean up unnecessary files
# RUN rm -rf /var/www/html/elgg/install/config/ \
#     && rm -f Dockerfile README.md *.sh

# # Health check
# HEALTHCHECK --interval=30s --timeout=3s \
#     CMD curl -f http://localhost/ || exit 1

# EXPOSE 80
# CMD ["apache2-foreground"]
########################################################################################################################

FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    netcat-openbsd \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli zip opcache \
    && a2enmod rewrite


# Change Apache DocumentRoot to /var/www/html/elgg
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/elgg|g' /etc/apache2/sites-available/000-default.conf

# Allow .htaccess overrides and access permissions
RUN echo '<Directory /var/www/html/elgg>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/elgg.conf && \
    a2enconf elgg

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html/elgg

# Install required PHP extensions
RUN apt-get update && apt-get install -y libicu-dev \
    && docker-php-ext-install intl \
    && docker-php-ext-enable intl \
    && rm -rf /var/lib/apt/lists/*

# Copy Elgg project files
COPY . /var/www/html/elgg

# Install PHP dependencies
RUN composer install --no-dev --prefer-dist

# Copy entrypoint script
# COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Fix permissions on Elgg files and folders
RUN chown -R www-data:www-data /var/www/html/elgg && \
    find /var/www/html/elgg -type d -exec chmod 755 {} \; && \
    find /var/www/html/elgg -type f -exec chmod 644 {} \;


# Ensure Apache runs as www-data
RUN chown -R www-data:www-data /var/www/html/elgg

EXPOSE 80
# ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
