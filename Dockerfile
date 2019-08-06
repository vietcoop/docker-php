FROM vietcoop/nginx:latest AS build_modules
FROM php:7.3-fpm-alpine

RUN set -xe \
    && get_latest_release() { \
        wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'; \
    } \
    && apk add --no-cache bash \
        bzip2 \
        curl-dev \
        freetype \
        gettext-libs \
        icu-libs \
        lame \
        libpng libxslt libmcrypt libass librtmp libssl1.1 libvpx libevent libtheora libvorbis \
        nginx \
        openssl-dev \
        opus \
        pcre-dev \
	postgresql-libs \
        protobuf-dev \
        x264-libs \
        x265-dev \
        sqlite-libs \
        supervisor \
    \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        bzip2-dev  \
        coreutils \
        curl-dev \
        cyrus-sasl-dev \
        freetype-dev \
        g++ \
        gettext-dev \
        zlib-dev \
        icu-dev \
        libedit-dev libevent-dev libressl-dev libxml2-dev libpng-dev libmcrypt-dev \
        libxslt-dev \
	postgresql-dev \
        sqlite-dev \
	&& export CFLAGS="$PHP_CFLAGS" \
        CPPFLAGS="$PHP_CPPFLAGS" \
        LDFLAGS="$PHP_LDFLAGS" \
    && docker-php-ext-install -j$(nproc) bcmath \
        bz2 \
        calendar \
        exif \
        gd \
        gettext \
        intl \
        mysqli pgsql pdo_mysql pdo_pgsql pdo_sqlite \
        soap sockets \
        xsl \
        opcache \
    && pecl install -o mcrypt-snapshot redis apcu \
    && docker-php-ext-enable mcrypt redis apcu \
    && echo "no\nyes\n/usr\nno\nyes\nno\nno\nno\n" | pecl install event \
    && docker-php-ext-enable event --ini-name zzz-docker-php-ext-event.ini \
    && cd /tmp \
    && mkdir -p /usr/src/php/ext \
    && apk del .build-deps \
    && rm -Rf /usr/local/etc/php-fpm.d/zz-docker.conf \
    && sed -i 's!access.log!; access.log!g' /usr/local/etc/php-fpm.d/docker.conf \
    && rm -rf /tmp/*

COPY rootfs /
COPY --from=build_modules /usr/local/lib /usr/local/lib

# Test nginx config.
RUN nginx -t
EXPOSE 80
RUN chmod a+x /start.bash
STOPSIGNAL SIGTERM
CMD ["/start.bash"]
