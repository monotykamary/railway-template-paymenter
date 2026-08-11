FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS source

ARG PAYMENTER_COMMIT=f8a884e670e9b9e5efb59ab5a7c606bf058b17d7
ARG PAYMENTER_ARCHIVE_SHA256=36f52aacaaee0bb2d2a0591033016f089992816fab5c22458623be6d11cc7d78

RUN apk add --no-cache ca-certificates curl tar \
    && curl -fsSL "https://github.com/Paymenter/Paymenter/archive/${PAYMENTER_COMMIT}.tar.gz" -o /tmp/paymenter.tar.gz \
    && echo "${PAYMENTER_ARCHIVE_SHA256}  /tmp/paymenter.tar.gz" | sha256sum -c - \
    && mkdir /src \
    && tar -xzf /tmp/paymenter.tar.gz --strip-components=1 -C /src \
    && rm /tmp/paymenter.tar.gz

FROM composer:2.10.2@sha256:4d71c3c2109c61d5415544264b59ad4087e4c5b7244481723664138fd36d5040 AS composer

FROM php:8.3-fpm-alpine@sha256:bf90236449d333cef008b1f01c72a3d4f11a6470a74629665e4c6b6158f03fc8 AS application

WORKDIR /app

RUN apk add --no-cache --update ca-certificates dcron curl git supervisor tar unzip nginx libpng-dev libxml2-dev libzip-dev icu-dev autoconf make g++ gcc libc-dev linux-headers gmp-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install bcmath gd pdo_mysql zip intl sockets gmp \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf make g++ gcc libc-dev

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY --from=source /src/composer.json /src/composer.lock ./
RUN composer install --no-dev --no-autoloader --no-scripts

COPY --from=source /src/ ./
RUN composer install --no-dev --optimize-autoloader \
    && cp .env.example .env \
    && chmod 777 -R bootstrap storage/* \
    && rm -rf .env bootstrap/cache/*.php \
    && chown -R nginx:nginx . \
    && rm /usr/local/etc/php-fpm.conf \
    && echo "* * * * * /usr/local/bin/php /app/artisan schedule:run >> /dev/null 2>&1" >> /var/spool/cron/crontabs/root \
    && mkdir -p /var/run/php /var/run/nginx

FROM node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32 AS assets

WORKDIR /app
COPY --from=source /src/package.json /src/package-lock.json ./
RUN npm ci
COPY --from=source /src/ ./
COPY --from=application /app/vendor /app/vendor
RUN npm run build

FROM application AS production

LABEL org.opencontainers.image.source="https://github.com/monotykamary/railway-template-paymenter"
LABEL org.opencontainers.image.version="1.5.7-railway.1"
LABEL org.opencontainers.image.licenses="MIT"

COPY --from=assets /app/public /app/public
RUN cp -r /app/themes /app/themes_default \
    && cp -r /app/extensions /app/extensions_default

ENV PAYMENTER_SKIP_DEFAULT=false

COPY upstream/default.conf /etc/nginx/http.d/default.conf
COPY upstream/www.conf /usr/local/etc/php-fpm.conf
COPY upstream/supervisord.conf /etc/supervisord.conf
COPY upstream/entrypoint.sh /usr/local/share/paymenter/entrypoint.sh
COPY bootstrap.php /app/railway/bootstrap.php
COPY railway-entrypoint.sh /usr/local/bin/paymenter-railway-entrypoint
RUN chmod 0755 /usr/local/bin/paymenter-railway-entrypoint /usr/local/share/paymenter/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/paymenter-railway-entrypoint"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
