# -----------------------------------------------
# Stage 1: Build Stage
# -----------------------------------------------
FROM composer:2 AS builder
WORKDIR /app
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

# -----------------------------------------------
# Stage 2: Runtime Stage (Production)
# -----------------------------------------------
FROM alpine:3.19

# Switch repositories to HTTP to bypass Proxy SSL verify errors
RUN sed -i 's/https/http/g' /etc/apk/repositories

# 1. Install PHP, JSON, and Opcache
RUN apk add --no-cache \
    php83 \
    php83-json \
    php83-opcache \
    && ln -sf /usr/bin/php83 /usr/bin/php

# 2. Configure PHP (Security & Performance)
RUN echo "opcache.enable=1" >> /etc/php83/conf.d/00_opcache.ini \
    && echo "opcache.enable_cli=1" >> /etc/php83/conf.d/00_opcache.ini \
    && echo "expose_php=Off" >> /etc/php83/php.ini \
    && echo "display_errors=Off" >> /etc/php83/php.ini \
    && echo "log_errors=On" >> /etc/php83/php.ini \
    && echo "error_log=/dev/stderr" >> /etc/php83/php.ini

# 3. Create non-root user
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -s /bin/sh -D appuser

WORKDIR /var/www/html

# 4. Copy only necessary files from builder and host
COPY --from=builder --chown=appuser:appuser /app/vendor ./vendor
COPY --chown=appuser:appuser public ./public

# 5. Switch to non-root user
USER appuser
ENV PORT=8080
EXPOSE ${PORT}

# 6. Start Server
# We can use 'sh -c' so the ${PORT} variable expands correctly at runtime
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT} -t public"]