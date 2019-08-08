PHP-FPM [![](https://images.microbadger.com/badges/version/vietcoop/nginx.svg)](https://microbadger.com/images/vietcoop/nginx "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/vietcoop/nginx.svg)](https://microbadger.com/images/vietcoop/nginx "Get your own image badge on microbadger.com")
====

    docker run -d --rm -p 8080:80 --name=testing vietcoop/php
    curl localhost:8080/
    docker stop testing

## Build local

    git clone git@github.com:vietcoop/docker-php.git
    cd docker-php
    docker build -t vietcoop/php:latest .
    docker push vietcoop/php:latest
