#!/usr/bin/env bash
# a script to build nginx with openssl-dev on ubuntu and debian

## to build using a newer version of gcc, run the following two lines
# $ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7
# $ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8

# select the nginx version to build
LATESTNGINX="1.15.3"

# choose where to put the build files
BUILDROOT="/home/sinc/nginx-edge"

# set core count for make
core_count="$(grep -c ^processor /proc/cpuinfo)"

# make sure all packages are up-to-date
sudo apt-get update
sudo apt-get upgrade -y

# install dependencies
sudo apt-get install -y \
  build-essential \
  gcc-8 \
  g++-8 \
  cmake \
  git \
  gnupg \
  golang \
  libpcre3-dev \
  curl \
  zlib1g-dev \
  libcurl4-openssl-dev

# delete any previous build directory
if [ -d "$BUILDROOT" ]; then
	sudo rm -rf "$BUILDROOT"
fi

# create the build directory
mkdir -p "$BUILDROOT"
cd "$BUILDROOT"

# download the latest sources for BoringSSL
git clone https://github.com/openssl/openssl.git
cd openssl

# configure openssl to not use old ciphers
./config no-ssl2 no-ssl3 no-weak-ssl-ciphers enable-tls1_3

# build openssl
make -j"$core_count"

# fetch the latest version of nginx
mkdir -p "$BUILDROOT/nginx"
cd "$BUILDROOT"/nginx
curl -L -O "http://nginx.org/download/nginx-$LATESTNGINX.tar.gz"
tar xzf "nginx-$LATESTNGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$LATESTNGINX"

# configure the nginx source to use boringSSL
sudo ./configure --prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/subsys/nginx \
        --user=www-data \
        --group=www-data \
        --with-threads \
        --with-file-aio \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_slice_module \
        --with-http_stub_status_module \
        --without-select_module \
        --without-poll_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
	--with-openssl="$BUILDROOT/openssl" \
	--with-cc-opt="-g -O3 -march=native -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -I $BUILDROOT/openssl" \
	--with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -L $BUILDROOT/openssl/" \

# build nginx
sudo make -j"$core_count"
sudo make install

# add systemd service file
cat <<EOL | sudo tee /lib/systemd/system/nginx.service
[Unit]
Description=NGINX with OpenSSL-dev
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/usr/bin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

# enable and start nginx
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# reload nginx config
sudo systemctl reload nginx.service
