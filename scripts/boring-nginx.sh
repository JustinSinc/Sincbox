#!/usr/bin/env bash
# a script to build nginx with boringssl on ubuntu and debian
LATESTNGINX="1.14.0"
BUILDROOT="/tmp/boring-nginx"

# Pre-req
sudo apt-get update
sudo apt-get upgrade -y

# Install deps
sudo apt-get install -y \
  build-essential \
  cmake \
  git \
  gnupg \
  gnupg-curl \
  golang \
  libpcre3-dev \
  curl \
  zlib1g-dev \
  libcurl4-openssl-dev

# make build root dir
mkdir -p $BUILDROOT
cd $BUILDROOT

# Download the latest sources for BoringSSL
git clone https://boringssl.googlesource.com/boringssl 
cd boringssl

# Patch BoringSSL for TLS1.3 support 
patch -p1 <<EOF
From cfc32a1e540e4f542egggd3008 Mon Sep 17 00:00:00 2001
From: Buik / Bassie <bassie@buik.locale>
Date: Tue, 09 Apr 2018 12:55:23 +0800

Subject: [PATCH] Enable TLS 1.3 on BoringSSL

Enable TLS 1.3 on BoringSSL.
Tested on Nginx 1.13.11 with BoringSSL chromium-stable and BoringSSL master (git branch April 09 2018)

--- 
 s3_lib.cc       | 2 +-
 ssl_test.cc     | 4 ++--
 ssl_versions.cc | 2 +-
 3 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/ssl/s3_lib.cc b/ssl/s3_lib.cc
index a3fc8d7..b28bbc8 100644
--- a/ssl/s3_lib.cc
+++ b/ssl/s3_lib.cc
@@ -201,7 +201,7 @@ bool ssl3_new(SSL *ssl) {
   // TODO(davidben): Move this field into |s3|, have it store the normalized
   // protocol version, and implement this pre-negotiation quirk in |SSL_version|
   // at the API boundary rather than in internal state.
-  ssl->version = TLS1_2_VERSION;
+  ssl->version = TLS1_3_VERSION;
   return true;
 }
 
diff --git a/ssl/ssl_test.cc b/ssl/ssl_test.cc
index 12f044c..cfc4af1 100644
--- a/ssl/ssl_test.cc
+++ b/ssl/ssl_test.cc
@@ -2607,7 +2607,7 @@ TEST(SSLTest, SetVersion) {
 
   // Zero is the default version.
   EXPECT_TRUE(SSL_CTX_set_max_proto_version(ctx.get(), 0));
-  EXPECT_EQ(TLS1_2_VERSION, ctx->conf_max_version);
+  EXPECT_EQ(TLS1_3_VERSION, ctx->conf_max_version);
   EXPECT_TRUE(SSL_CTX_set_min_proto_version(ctx.get(), 0));
   EXPECT_EQ(TLS1_VERSION, ctx->conf_min_version);
 
@@ -2640,7 +2640,7 @@ TEST(SSLTest, SetVersion) {
   EXPECT_FALSE(SSL_CTX_set_min_proto_version(ctx.get(), 0x1234));
 
   EXPECT_TRUE(SSL_CTX_set_max_proto_version(ctx.get(), 0));
-  EXPECT_EQ(TLS1_2_VERSION, ctx->conf_max_version);
+  EXPECT_EQ(TLS1_3_VERSION, ctx->conf_max_version);
   EXPECT_TRUE(SSL_CTX_set_min_proto_version(ctx.get(), 0));
   EXPECT_EQ(TLS1_1_VERSION, ctx->conf_min_version);
 }
diff --git a/ssl/ssl_versions.cc b/ssl/ssl_versions.cc
index 73ea26f..da10cb2 100644
--- a/ssl/ssl_versions.cc
+++ b/ssl/ssl_versions.cc
@@ -189,7 +189,7 @@ static bool set_max_version(const SSL_PROTOCOL_METHOD *method, uint16_t *out,
                             uint16_t version) {
   // Zero is interpreted as the default maximum version.
   if (version == 0) {
-    *out = TLS1_2_VERSION;
+    *out = TLS1_3_VERSION;
     return true;
   }
EOF

# Patch boringSSL to report version as OpenSSL 1.1.1
sed -i 's/OpenSSL 1\.[[:digit:]]\+\.[[:digit:]]\+/OpenSSL 1.1.1/' crypto.h

# Build OpenSSL
mkdir build 
cd $BUILDROOT/boringssl/build
cmake ..
make

# Make an .openssl directory for nginx and then symlink BoringSSL's include directory tree
mkdir -p "$BUILDROOT/boringssl/.openssl/lib"
cd "$BUILDROOT/boringssl/.openssl"
ln -s ../include include

# Copy the BoringSSL crypto libraries to .openssl/lib so nginx can find them
cd "$BUILDROOT/boringssl"
cp "build/crypto/libcrypto.a" ".openssl/lib"
cp "build/ssl/libssl.a" ".openssl/lib"

# Prep nginx
mkdir -p "$BUILDROOT/nginx"
cd $BUILDROOT/nginx
curl -L -O https://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
curl -L -O "http://nginx.org/download/nginx-$LATESTNGINX.tar.gz"
tar xzf "nginx-$LATESTNGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$LATESTNGINX"

# Run the config with default options and append any additional options specified by the above section
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
	--with-openssl="$BUILDROOT/boringssl" \
	--with-openssl-opt=enable-tls1_3
	--with-cc-opt="-g -O2 -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -I $BUILDROOT/boringssl/.openssl/include/" \
	--with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -L $BUILDROOT/boringssl/.openssl/lib/" \

# Fix "Error 127" during build
touch "$BUILDROOT/boringssl/.openssl/include/openssl/ssl.h"

# Build nginx
sudo make
sudo make install

# Add systemd service
cat >/lib/systemd/system/nginx.service <<EOL
[Unit]
Description=NGINX with BoringSSL
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

# NOTE: The below fails on Docker containers but i *think* will work elsewhere
# Enable & start service
sudo systemctl enable nginx.service
sudo systemctl start nginx.service

# Finish script
sudo systemctl reload nginx.service
