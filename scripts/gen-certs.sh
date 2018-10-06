#!/bin/bash

if [ -z "$CERTDIR" ]; then
  CERTDIR="certs"
fi
echo "Generating certs into $CERTDIR"

if [ -e $CERTDIR/ca.pem ] && [ $CERTDIR/ca.pem -nt $0 ]
then
    echo "Already up to date"
    exit 0
fi

cfssl gencert -initca ca-csr.json | cfssljson -bare $CERTDIR/ca

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -profile kubernetes admin-csr.json | cfssljson -bare $CERTDIR/admin

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -profile kubernetes controller-manager-csr.json | cfssljson -bare $CERTDIR/controller-manager

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -profile kubernetes scheduler-csr.json | cfssljson -bare $CERTDIR/scheduler

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -profile kubernetes proxy-csr.json | cfssljson -bare $CERTDIR/proxy

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -profile kubernetes service-accounts-csr.json | cfssljson -bare $CERTDIR/service-accounts
