#!/bin/bash

if [ ! -d "./certificate-signature" ]; then
  echo "请先执行gen-root-ca.sh生成根证书，或执行./gen-all.sh进行完整生成。"
  exit 1
fi
cd ./certificate-signature
rm -rf ./intermediate
mkdir intermediate
cd intermediate
# private：存放中间证书的私钥
# csr：存放中间证书的证书签发申请档
# cece：存放中间证书
# chain：存放中间证书的证书串链
# signed_certs：存放中间证书签发过的证书的副本
mkdir cert chain csr private signed_certs
touch index.txt index.txt.attr serial
echo 0001 >serial
echo unique_subject = no >index.txt.attr
# # 拷贝中间CA生成配置文件
cp ../../openssl_intermediate_ca.conf ./openssl_intermediate_ca.conf
# # 创建中间CA私钥证书
openssl genrsa -out private/intermediate_ca.key.pem 4096
envStr=$(uname -a)
# # 生成中间CA签名申请文件
if [[ $envStr =~ 'MINGW' ]]; then
  openssl req -config openssl_intermediate_ca.conf -subj "//C={{CA_C}}\ST={{CA_ST}}\L={{CA_L}}\O={{CA_O}}\OU={{CA_OU}}\CN={{CA_CN}}-INTERMEDIATE-CA" -new -sha256 -key private/intermediate_ca.key.pem -out csr/intermediate_ca.csr.pem
else
  openssl req -config openssl_intermediate_ca.conf -subj "/C={{CA_C}}\ST={{CA_ST}}\L={{CA_L}}\O={{CA_O}}\OU={{CA_OU}}\CN={{CA_CN}}-INTERMEDIATE-CA" -new -sha256 -key private/intermediate_ca.key.pem -out csr/intermediate_ca.csr.pem
fi
# # 使用根证书签发中间证书
cd ../root
openssl ca -config openssl_root_ca.conf -extensions intermediate_ca -days 3600 -notext -md sha256 -in ../intermediate/csr/intermediate_ca.csr.pem -out ../intermediate/cert/intermediate_ca.cert.pem
# 验证中间证书
openssl x509 -noout -text -in ../intermediate/cert/intermediate_ca.cert.pem
openssl verify -CAfile cert/root_ca.cert.pem ../intermediate/cert/intermediate_ca.cert.pem
# 完善中间CA的证书链
cd ../intermediate
cat cert/intermediate_ca.cert.pem ../root/cert/root_ca.cert.pem >chain/chain.cert.pem
cd ../../
echo "Generate INTERMEDIATE CA success !"
