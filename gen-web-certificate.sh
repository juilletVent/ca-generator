#!/bin/bash
if [ ! -d "./certificate-signature" ]; then
  echo "请先执行gen-root-ca.sh生成根证书，或执行./gen-all.sh进行完整生成。"
  exit 1
fi
cd ./certificate-signature
rm -rf ./server
mkdir server
cd server
# 拷贝站点证书生成配置文件
cp ../../openssl_csr.conf ./openssl_csr.conf
# 创建站点证书私钥
openssl genrsa -out server.key.pem 4096
envStr=$(uname -a)
# 创建证书签发申请
if [[ $envStr =~ 'MINGW' ]]; then
  openssl req -config openssl_csr.conf -subj "//C={{CA_C}}\ST={{CA_ST}}\L={{CA_L}}\O={{CA_O}}\OU={{CA_OU}}\CN={{CA_CN}}-WEB" -new -sha256 -key server.key.pem -out server.csr.pem
else
  openssl req -config openssl_csr.conf -subj "/C={{CA_C}}\ST={{CA_ST}}\L={{CA_L}}\O={{CA_O}}\OU={{CA_OU}}\CN={{CA_CN}}-WEB" -new -sha256 -key server.key.pem -out server.csr.pem
fi
cd ../intermediate
# 使用中间CA配置签署站点证书
openssl ca -config openssl_intermediate_ca.conf -extensions server_cert -days 1800 -notext -md sha256 -in ../server/server.csr.pem -out ../server/server.cert.pem
# 检查证书
openssl x509 -noout -text -in ../server/server.cert.pem
# 检查完成性
openssl verify -CAfile chain/chain.cert.pem ../server/server.cert.pem
cd ../server
# 完善站点证书信任链
cat server.cert.pem ../intermediate/chain/chain.cert.pem >server_fullchain.cert.pem
cp server_fullchain.cert.pem server_fullchain.cert.crt

echo "Generate websit certificate success !"
