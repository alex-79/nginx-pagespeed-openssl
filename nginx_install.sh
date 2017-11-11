#!/bin/sh

# apt-get install build-essential ca-certificates zlib1g-dev libpcre3 libpcre3-dev tar unzip libssl-dev checkinstall

OPENSSL_VER='1.1.0c'
NPS_VER='1.12.34.2'
NGINX_VER='1.13.0'

cd /opt
wget -c https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz
tar -xzvf openssl-$OPENSSL_VER.tar.gz
rm openssl-$OPENSSL_VER.tar.gz

wget https://github.com/pagespeed/ngx_pagespeed/archive/v$NPS_VER-beta.zip
unzip v$NPS_VER-beta.zip
rm v$NPS_VER-beta.zip
cd ngx_pagespeed-$NPS_VER-beta/
wget https://dl.google.com/dl/page-speed/psol/$NPS_VER-x64.tar.gz
tar -xzvf $NPS_VER-x64.tar.gz
rm $NPS_VER-x64.tar.gz

cd /opt
wget -qO- http://nginx.org/download/nginx-$NGINX_VER.tar.gz | tar zxf -

cd nginx-$NGINX_VER
 ./configure \
 --prefix=/etc/nginx \
 --sbin-path=/usr/sbin/nginx \
 --conf-path=/etc/nginx/nginx.conf \
 --error-log-path=/var/log/nginx/error.log \
 --http-log-path=/var/log/nginx/access.log \
 --pid-path=/var/run/nginx.pid \
 --lock-path=/var/run/nginx.lock \
 --http-client-body-temp-path=/var/cache/nginx/client_temp \
 --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
 --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
 --user=www-data \
 --group=www-data \
 --without-http_ssi_module \
 --without-http_scgi_module \
 --without-http_uwsgi_module \
 --without-http_geo_module \
 --without-http_split_clients_module \
 --without-http_memcached_module \
 --without-http_empty_gif_module \
 --without-http_browser_module \
 --with-threads \
 --with-file-aio \
 --with-http_ssl_module \
 --with-http_v2_module \
 --with-ipv6 \
 --with-http_mp4_module \
 --with-http_auth_request_module \
 --with-http_slice_module \
 --with-http_stub_status_module \
 --with-openssl=/opt/openssl-$OPENSSL_VER \
 --add-module=/opt/ngx_pagespeed-$NPS_VER-beta 

make -j `nproc`

#make install
checkinstall --pkgname=nginx --pkgversion=$NGINX_VER --nodoc --install=no

dpkg -i /opt/nginx-$NGINX_VER/nginx_$NGINX_VER*.deb

cat > /lib/systemd/system/nginx.service << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /var/cache/nginx
mkdir -p /var/log/nginx

systemctl enable nginx.service

