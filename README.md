[Docker PHP](https://github.com/vietcoop/docker-php)
====

    docker run -d --rm -p 8080:80 --name=testing vietcoop/php
    curl localhost:8080/
    docker stop testing
