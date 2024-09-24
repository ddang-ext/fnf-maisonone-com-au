#!/usr/bin/env bash

# Configure php-fpm
go-replace --mode=lineinfile --regex \
    -s '^[\s;]*access.format[\s]*='  -r 'access.format = "%R - %u %t \"%m %r%Q%q\" %s %f cpu:%C%% mem:%{megabytes}M reqTime:%d"' \
    -- /opt/docker/etc/php/fpm/pool.d/application.conf
# listen on public IPv6 port
go-replace --mode=line --regex \
    -s '^[\s;]*listen[\s]*=' -r 'listen = [::]:9000' \
    -- /opt/docker/etc/php/fpm/pool.d/application.conf \
        /opt/docker/etc/php/fpm/php-fpm.conf
