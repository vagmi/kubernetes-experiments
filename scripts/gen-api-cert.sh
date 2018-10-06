#!/bin/bash

if [ -z "$CERTDIR" ]; then
  CERTDIR="certs"
fi

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -hostname 10.32.0.1,${instance},${publicip},${privateip},127.0.0.1,kuberentes.default \
  -profile kubernetes kubernetes-csr.json | cfssljson -bare $CERTDIR/kubernetes
