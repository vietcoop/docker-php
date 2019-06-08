FROM nginx:1.14.2-alpine AS build_modules

RUN \
    get_latest_release() { \
        wget -qO- "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'; \
    } \
    && apk update \
    && apk add curl wget \
    && apk add curl-dev protobuf-dev pcre-dev openssl-dev msgpack-c-dev \
    && apk add build-base cmake autoconf automake git linux-headers gd-dev geoip-dev libxml2-dev libxslt-dev openssl-dev paxmark pcre-dev pkgconf zlib-dev \
    && cd ~ \
    && cd ~ \
    && git clone -b release-1.14.2 https://github.com/nginx/nginx.git \
    && cd $HOME/nginx \
        && auto/configure \
            --prefix=/var/lib/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --pid-path=/run/nginx/nginx.pid --lock-path=/run/nginx/nginx.lock --http-client-body-temp-path=/var/tmp/nginx/client_body \
            --http-proxy-temp-path=/var/tmp/nginx/proxy \
            --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
            --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
            --http-scgi-temp-path=/var/tmp/nginx/scgi \
            --user=nginx --group=nginx --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_mp4_module \
            --with-http_gunzip_module --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-mail=dynamic \
            --with-mail_ssl_module --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module \
    && make modules \
    && ls -l objs \
    && echo Made \
    && ls -l /usr/local/lib \
    && ls -l $HOME/nginx/objs

FROM php:7.2-fpm-alpine

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
        libedit-dev \
        libevent-dev \
        libressl-dev \
        libxml2-dev \
        libpng-dev \
        libmcrypt-dev \
        libxslt-dev \
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
        mysqli \
        pdo_mysql \
        pdo_sqlite \
        soap \
        sockets \
        xsl \
        zip \
        opcache \
    && pecl install -o mcrypt-snapshot redis apcu \
    && docker-php-ext-enable mcrypt redis apcu \
    && echo "no\nyes\n/usr\nno\nyes\nno\nno\nno\n" | pecl install event \
    && docker-php-ext-enable event --ini-name zzz-docker-php-ext-event.ini \
    && cd /tmp \
    && mkdir -p /usr/src/php/ext \
    && apk del .build-deps \
    && mkdir -p /etc/nginx \
    && mkdir -p /run/nginx \
    && rm -Rf /etc/nginx/nginx.conf \
    && mkdir -p /etc/nginx/sites-available/ \
    && mkdir -p /etc/nginx/sites-enabled/ \
    && mkdir -p /app/public/ \
    && ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf \
    && rm -Rf /usr/local/etc/php-fpm.d/zz-docker.conf \
    && sed -i 's!access.log!; access.log!g' /usr/local/etc/php-fpm.d/docker.conf \
    && rm -rf /tmp/* \
    && mkdir -p /tmp/nginx \
    && chown -R www-data /tmp/nginx

COPY rootfs /
COPY --from=build_modules /usr/local/lib /usr/local/lib

# Test nginx config.
RUN nginx -t
EXPOSE 80
RUN chmod a+x /start.bash
STOPSIGNAL SIGTERM
CMD ["/start.bash"]
