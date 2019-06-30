#!/bin/sh

apt-get install build-essential ca-certificates zlib1g-dev libpcre3 libpcre3-dev tar unzip libssl-dev checkinstall git uuid-dev libgeoip-dev

OPENSSL_VER=1.1.0k
NPS_VER=1.12.34.3-stable
NGINX_VER=1.17.1

cd /opt
wget -c https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz
tar -xzvf openssl-$OPENSSL_VER.tar.gz
rm openssl-$OPENSSL_VER.tar.gz

wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VER}.zip
unzip v${NPS_VER}.zip
rm v${NPS_VER}.zip
NPS_DIR=$(find . -name "*pagespeed-ngx-${NPS_VER}" -type d | sed -e 's/\.\///g')
cd $NPS_DIR

[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})
rm $(basename ${psol_url})

cd /opt
git clone https://github.com/google/ngx_brotli
cd /opt/ngx_brotli && git submodule update --init

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
 --without-http_split_clients_module \
 --without-http_memcached_module \
 --without-http_empty_gif_module \
 --without-http_browser_module \
 --with-http_geoip_module \
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
 --add-module=/opt/$NPS_DIR \
 --add-module=/opt/ngx_brotli

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
