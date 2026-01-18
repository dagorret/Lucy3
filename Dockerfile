# --- ETAPA 1: php-base (Arquitectura de Conectividad) ---
FROM debian:trixie-slim AS php-base

# 1. Preparación del repositorio Sury para PHP 8.4
RUN apt-get update && apt-get install -y \
    lsb-release ca-certificates curl gnupg2 \
    && curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# 2. Instalación de paquetes (Axiomas de Lucy)
RUN apt-get update && apt-get install -y \
    php8.4-fpm \
    php8.4-mysql \
    php8.4-mbstring \
    php8.4-xml \
    php8.4-zip \
    php8.4-intl \
    php8.4-curl \
    php8.4-bcmath \
    php8.4-soap \
    php8.4-redis \
    git unzip nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- NOTAS DE DISEÑO PRESERVADAS ---
# php8.4-curl:   Microsoft Graph y Moodle REST
# php8.4-soap:   Servicios antiguos de Moodle
# php8.4-redis:  Tokens de Azure/EntraID
# php8.4-ldap:   (Opcional) Active Directory local
# -----------------------------------------------

# 3. Configuración de Red y Composer
RUN sed -i 's|listen = /run/php/php8.4-fpm.sock|listen = 9000|' /etc/php/8.4/fpm/pool.d/www.conf
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# --- ETAPA 2: development (Entorno de Carlos) ---
FROM php-base AS development
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} laravel && \
    useradd -u ${USER_ID} -g laravel -m -s /bin/bash laravel

# FIX DEFINITIVO:
# 1. Creamos carpetas.
# 2. Desactivamos el log de error de FPM en el archivo de config para que use stderr.
RUN mkdir -p /run/php /var/log/php && \
    sed -i 's|error_log = /var/log/php8.4-fpm.log|error_log = /proc/self/fd/2|' /etc/php/8.4/fpm/php-fpm.conf && \
    chown -R laravel:laravel /var/www /var/log/php /run/php

USER laravel

# El flag -O es clave en PHP 8.4 para ignorar configuraciones de log conflictivas
CMD ["php-fpm8.4", "-F", "-R", "-O"]

# --- ETAPA 3: production (Versión Final) ---
FROM php-base AS production
RUN groupadd -g 1000 laravel && useradd -u 1000 -g laravel -m -s /bin/bash laravel
COPY --chown=laravel:laravel . .
RUN composer install --no-dev --optimize-autoloader --no-scripts
USER laravel
CMD ["php-fpm8.4", "-F"]
