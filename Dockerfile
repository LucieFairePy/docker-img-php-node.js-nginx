# Dockerfile - Steam Manifest All-in-One
# Base: Debian avec Node.js 18 + Nginx + PHP 8.1
# Pour Pterodactyl Panel

FROM node:18-bullseye-slim

LABEL author="Steam Manifest" \
      maintainer="steam-manifest" \
      description="Nginx + PHP 8.1 + Node.js 18 pour Pterodactyl"

USER root

# Installation des dépendances système
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    gnupg2 \
    lsb-release \
    debian-archive-keyring \
    && rm -rf /var/lib/apt/lists/*

# Ajouter le repository PHP (Sury)
RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Installation Nginx + PHP 8.1
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-cli \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    php8.1-zip \
    php8.1-gd \
    php8.1-intl \
    php8.1-bcmath \
    php8.1-opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Créer l'utilisateur container (standard Pterodactyl)
RUN useradd -m -d /home/container -s /bin/bash container

# Créer les dossiers nécessaires avec bonnes permissions
RUN mkdir -p /home/container/logs \
    /home/container/temp \
    /home/container/www \
    /home/container/bot \
    /tmp/nginx \
    /run/php \
    && chown -R container:container /home/container \
    && chown -R container:container /var/log/nginx \
    && chown -R container:container /var/lib/nginx \
    && chown -R container:container /etc/nginx \
    && chown -R container:container /run/php \
    && chmod -R 755 /home/container

# Configuration PHP-FPM pour utiliser l'user container
RUN sed -i 's/user = www-data/user = container/g' /etc/php/8.1/fpm/pool.d/www.conf && \
    sed -i 's/group = www-data/group = container/g' /etc/php/8.1/fpm/pool.d/www.conf && \
    sed -i 's/listen.owner = www-data/listen.owner = container/g' /etc/php/8.1/fpm/pool.d/www.conf && \
    sed -i 's/listen.group = www-data/listen.group = container/g' /etc/php/8.1/fpm/pool.d/www.conf

# Optimisations PHP
RUN sed -i 's/upload_max_filesize = .*/upload_max_filesize = 500M/g' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 500M/g' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/memory_limit = .*/memory_limit = 512M/g' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/g' /etc/php/8.1/fpm/php.ini

# Variables d'environnement
ENV USER=container \
    HOME=/home/container \
    NODE_ENV=production

WORKDIR /home/container

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node --version && php --version && nginx -v || exit 1

# Entrypoint par défaut (sera remplacé par Pterodactyl)
CMD ["/bin/bash"]
