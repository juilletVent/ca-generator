#!/bin/bash

rm -rf ./certificate-signature
mkdir certificate-signature

# ======================= 创建根CA =======================
./gen-root-ca.sh

# ======================= 创建中间CA =======================
./gen-intermediate-ca.sh

# ======================= 创建站点证书 =======================
./gen-web-certificate.sh
