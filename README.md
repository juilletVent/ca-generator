## 自签证书脚本

将自签证书相关流程自动化，只需要少数几个操作即可生成带有中间 CA 的自签证书与 CA 证书

## 使用方法

请先配置生成前所需信息（CA 基本信息与站点域名等信息）

### 必须配置

**修改文件`openssl_intermediate_ca.conf`中的`alt_names`段下的相关站点配置，将您需要进行自签的域名与 IP 配置进去**

### 可选配置

如果不配置不影响使用，如果您不在乎 CA 与证书相关的描述与所有者信息的话（主要描述的是区域信息、公司信息、所有者信息、邮箱）

修改默认配置文件`openssl_config_default.properties`，具体配置含义，请参考：[opensslconf 配置](https://www.phildev.net/ssl/opensslconf.html)中的 req_distinguished_name 段

### 关于 Cmder 执行环境

Cmder 执行环境：find 可能会命中 DOS 的 find 命令，而不是 MinGW 的模拟的 find 命令，请正确配置您的Cmder环境变量，并在cmder中正确执行。

如果您清楚如何修改证书配置信息，可以自行修改配置信息，然后直接生成。或者使用 linux 环境、Windows 下的 WSL 环境、Unix 环境或者 GitBash 环境

### 开始生成

如果您的执行环境是 Linux/Unix，请赋予相关文件可执行权限：

```
chmod +x ./gen-*
```

执行的过程中会多次询问是否签名(y/n)，一路 y 即可

```bash
# 生成所有证书（CA根证书+中间CA证书+站点证书），将删除certificate-signature下所有文件，并重建所有证书信息
./gen-all.sh
# 重新签发CA根证书，将删除certificate-signature/root下所有文件，并重新生成根CA证书信息
./gen-root-ca.sh
# 重新签发中间CA证书，将删除certificate-signature/intermediate下所有文件，并重新生成中间CA证书信息
./gen-intermediate-ca.sh
# 重新签发站点证书，将删除certificate-signature/server下所有文件，并重新生成站点证书信息
./gen-web-certificate.sh
```

## 结果文件说明

**关于根证书**：certificate-signature/root 文件夹下存放了根证书相关信息，通常只需要将 certificate-signature/root/cert/root_ca.cert.crt 分发给客户机，导入到受信任的根证书列表即可

关于中间证书：certificate-signature/intermediate 文件夹下存放了中间 CA 证书相关信息，一般来说不需要管，如果过期，只需要重新生成中间证书即可（根证书过期时间非常久[100 年]，其实中间证书的过期时间也蛮久的[10 年]）

**关于站点证书**：certificate-signature/server 文件夹下存放了站点证书相关信息，相关站点配置 HTTPS 所需要的证书与秘钥文件存放在此处

- 证书：server_fullchain.cert.crt 或者 server_fullchain.cert.pem （内容一样，拓展名不一样而已）
- 私钥：server.key.pem
