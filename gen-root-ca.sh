#!/bin/bash

if [ ! -d "./certificate-signature" ]; then
  mkdir certificate-signature
fi
cd ./certificate-signature
rm -rf ./root
mkdir root
cd root
# private 目录存放根证书的私钥
# cert 目录存放根证书
# signed_certs 目录存放根证书签发过的证书的副本
mkdir cert private signed_certs
touch index.txt index.txt.attr serial
echo 0001 >serial
echo unique_subject = no > index.txt.attr
# 拷贝CA生成配置文件
cp ../../openssl_root_ca.conf ./openssl_root_ca.conf
# 生成CA私钥
openssl genrsa -out private/root_ca.key.pem 4096
# 生成CA证书，因为MinGW的模块转换问题，需要辨别shell运行环境到底是Linux环境还是MinGW模拟环境
envStr=$(uname -a)
if [[ $envStr =~ 'MINGW' ]]; then
  # 如果是MinGW环境则使用这个路径
  openssl req -config openssl_root_ca.conf -subj "//C=CN\ST=CQ\L=CQ\O=JulyWind\OU=JulyWind\CN=JulyWind-ROOT-CA" -new -x509 -days 36500 -sha256 -extensions root_ca -key private/root_ca.key.pem -out cert/root_ca.cert.pem
else
  # 如果是Linux环境环境则使用这个路径
  openssl req -config openssl_root_ca.conf -subj "/C=CN/ST=CQ/L=CQ/O=JulyWind/OU=JulyWind/CN=JulyWind-ROOT-CA" -new -x509 -days 36500 -sha256 -extensions root_ca -key private/root_ca.key.pem -out cert/root_ca.cert.pem
fi
# 查看CA信息
openssl x509 -noout -text -in cert/root_ca.cert.pem
# 拷贝一个，方便win系统进行根证书导入
cp ./cert/root_ca.cert.pem ./cert/root_ca.cert.crt
echo "Generate ROOT CA success !"
cd ../../
