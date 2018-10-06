#!/bin/bash

if [ -z "$CERTDIR" ]; then
  CERTDIR="certs"
fi

jq ".CN=\"system:node:${instance}\"" kubelet-csr.json > $CERTDIR/kubelet-${instance}-csr.json

cfssl gencert \
  -ca $CERTDIR/ca.pem \
  -ca-key $CERTDIR/ca-key.pem \
  -config ca-config.json \
  -hostname ${instance},${publicip},${privateip} \
  -profile kubernetes $CERTDIR/kubelet-${instance}-csr.json | cfssljson -bare $CERTDIR/${instance}
