#!/bin/bash

SG_TLS_CONFIG=("searchguard.ssl.transport.pemcert_filepath" \
                              "searchguard.ssl.transport.pemkey_filepath" \
                              "searchguard.ssl.transport.pemtrustedcas_filepath" \
                              "searchguard.ssl.transport.enforce_hostname_verification" \
                              "searchguard.authcz.admin_dn" 
)

# Default certificates and keys
tls_dir="tls"
ca_crt="$tls_dir/ca.crt"
ca_key="$tls_dir/ca.key"
admin_crt="$tls_dir/admin-node.crt"
admin_csr="$tls_dir/admin-node.csr"
admin_key="$tls_dir/admin-node.key"
node_crt="$tls_dir/node.crt"
node_csr="$tls_dir/node.csr"
node_key="$tls_dir/node.key"

# https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-tls.html
# Not using bin/elasticsearch-certutil, because it generates PKCS#12
# And Search Guard expects PKCS#8 as described here:
# https://github.com/floragunncom/search-guard/issues/402
# OpenSSL commands are from https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
function setup_tls_config(){
    yum install openssl -y > /dev/null
    for sg_tls_config in ${SG_TLS_CONFIG[@]} ; do
        sed -i "/${sg_tls_config}/d" config/elasticsearch.yml
    done

    # TLS file path is relative to config directory for Search Guard
    pushd config 
    mkdir -p "$tls_dir"

    echo "Creating CA certificate and key"
    openssl genrsa -out "$ca_key" 4096
    openssl req -x509 -new -nodes -key "$ca_key" -subj "/O=Elasticsearch with Search Guard/OU=Container/CN=Elasticsearch with Search Guard" -sha256 -days 1024 -out "$ca_crt"
    
    echo "Creating Admin certificate and key"
    openssl genpkey -out "$admin_key" -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    openssl req -new -sha256 -key "$admin_key" -subj "/C=de/L=test/O=client/OU=client/CN=kirk" -out "$node_csr"
    openssl x509 -req -in "$node_csr" -CA "$ca_crt" -CAkey "$ca_key" -CAcreateserial -out "$admin_crt" -days 1024 -sha256

    echo "Creating regular node certificate and key"
    openssl genpkey -out "$node_key" -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    openssl req -new -sha256 -key "$node_key" -subj "/C=de/L=test/O=client/OU=client/CN=lars" -out "$node_csr"
    openssl x509 -req -in "$node_csr" -CA "$ca_crt" -CAkey "$ca_key" -CAcreateserial -out "$node_crt" -days 1024 -sha256

    chmod 770 "$tls_dir"
    find "$tls_dir" -type f -exec chmod 660 {} \;
    chown elasticsearch "$tls_dir" -R

    popd

    echo "
# AUTO GENERATED TLS SETTINGS #
# searchguard.ssl.transport.pemkey_password # no password
searchguard.ssl.transport.pemcert_filepath: $node_crt
searchguard.ssl.transport.pemkey_filepath: $node_key
searchguard.ssl.transport.pemtrustedcas_filepath: $ca_crt
searchguard.ssl.transport.enforce_hostname_verification: false

searchguard.authcz.admin_dn:
  - CN=kirk,OU=client,O=client,L=test,C=de

searchguard.nodes_dn:
  - CN=lars,OU=client,O=client,L=test,C=de
" >> config/elasticsearch.yml

    yum remove openssl -y > /dev/null
}

function configure_search_guard(){
    while ! curl --connect-timeout 1 127.0.0.1:9200 1>/dev/null 2>/dev/null; do
        sleep 1 
    done
    sleep 1
    echo "Starting sgadmin"
    sgadmin.sh -cd plugins/search-guard-6/sgconfig/ -icl -nhnv -cacert "config/${ca_crt}" -cert "config/${admin_crt}" -key "config/${admin_key}"
}

#https://docs.search-guard.com/latest/search-guard-installation#adding-the-tls-configuration
for sg_tls_config in ${SG_TLS_CONFIG[@]} ; do
    if ! grep "$sg_tls_config" config/elasticsearch.yml ; then
        echo "[WARN] Unable to find required Search Guard TLS config: $sg_tls_config"
        echo "[WARN] Regenerating TLS settings"
        setup_tls_config
        break
    fi
done

# Start in background because we can only run sgadmin when ES is up
configure_search_guard &

# Exec the original ES entrypoint
exec /usr/local/bin/docker-entrypoint.sh

