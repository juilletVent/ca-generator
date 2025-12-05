#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示横幅
function show_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║          ${GREEN}三级证书自签名生成系统${CYAN}                  ║${NC}"
    echo -e "${CYAN}║          ${YELLOW}Certificate Generator Tool${CYAN}                ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示菜单
function show_menu() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  请选择要执行的操作：${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} 生成所有证书 (根CA + 中间CA + 站点证书)"
    echo -e "  ${CYAN}[2]${NC} 仅生成根CA证书"
    echo -e "  ${CYAN}[3]${NC} 仅生成中间CA证书"
    echo -e "  ${CYAN}[4]${NC} 仅生成站点证书"
    echo -e "  ${CYAN}[5]${NC} 查看当前证书信息"
    echo -e "  ${CYAN}[6]${NC} 查看CA配置信息"
    echo -e "  ${CYAN}[7]${NC} 清理所有生成的证书"
    echo -e "  ${CYAN}[0]${NC} 退出系统"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 全局配置变量
declare -A CA_CONFIG=()

# 加载配置文件
function load_config() {
    while read line; do
        if [ "${line:0:1}" == "#" -o "${line:0:1}" == "" ]; then
            continue
        fi
        key=${line/=*/}
        value=${line#*=}
        CA_CONFIG["$key"]="$value"
    done <./openssl_config_default.properties
}

# 查看CA配置信息
function view_config() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              当前CA配置信息                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}基本信息:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}国家代码 (C):${NC}           ${CA_CONFIG[CA_C]}"
    echo -e "  ${CYAN}省份/州 (ST):${NC}           ${CA_CONFIG[CA_ST]}"
    echo -e "  ${CYAN}城市 (L):${NC}               ${CA_CONFIG[CA_L]}"
    echo -e "  ${CYAN}组织名称 (O):${NC}           ${CA_CONFIG[CA_O]}"
    echo -e "  ${CYAN}组织单位 (OU):${NC}          ${CA_CONFIG[CA_OU]}"
    echo -e "  ${CYAN}联系邮箱:${NC}               ${CA_CONFIG[CA_EMAIL]}"
    echo ""
    
    echo -e "${YELLOW}证书颁发机构名称:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}根CA (CN):${NC}              ${CA_CONFIG[CA_CN]}"
    echo -e "  ${GREEN}中间CA (CN):${NC}            ${CA_CONFIG[CA_INTERMEDIATE_CN]}"
    echo ""
    
    if [ ! -z "${CA_CONFIG[CA_CRL_URL]}" ] || [ ! -z "${CA_CONFIG[CA_OCSP_URL]}" ]; then
        echo -e "${YELLOW}高级配置 (可选):${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        if [ ! -z "${CA_CONFIG[CA_CRL_URL]}" ]; then
            echo -e "  ${CYAN}CRL分发点:${NC}              ${CA_CONFIG[CA_CRL_URL]}"
        fi
        if [ ! -z "${CA_CONFIG[CA_OCSP_URL]}" ]; then
            echo -e "  ${CYAN}OCSP响应器:${NC}             ${CA_CONFIG[CA_OCSP_URL]}"
        fi
        echo ""
    fi
    
    echo -e "${CYAN}[提示]${NC} 如需修改配置，请编辑 ${YELLOW}openssl_config_default.properties${NC} 文件"
}

# 生成配置文件
function generate_config() {
    echo -e "${YELLOW}[INFO]${NC} 开始处理配置文件..."
    
    # 加载配置
    load_config
    
    # 替换配置文件中的占位符
    for element in $(find . -name "*.conf" -type f); do
        conf_file=$element
        if [ -f $conf_file ]; then
            for key in ${!CA_CONFIG[@]}; do
                value=${CA_CONFIG[$key]}
                value=${value//\//\\\/}
                sed -i "s/{{$key}}/${value}/g" $conf_file
            done
        fi
    done
    
    echo -e "${GREEN}[SUCCESS]${NC} 配置文件处理完成"
}

# 生成根CA证书
function generate_root_ca() {
    echo -e "${YELLOW}[INFO]${NC} 开始生成根CA证书..."
    
    if [ ! -d "./certificate-signature" ]; then
        mkdir certificate-signature
    fi
    cd ./certificate-signature
    rm -rf ./root
    mkdir root
    cd root
    
    # 创建目录结构
    mkdir cert private signed_certs
    touch index.txt index.txt.attr serial
    echo 0001 >serial
    echo unique_subject = no > index.txt.attr
    
    # 拷贝配置文件
    cp ../../openssl_root_ca.conf ./openssl_root_ca.conf
    
    # 生成CA私钥 (RSA 4096)
    echo -e "${YELLOW}[INFO]${NC} 生成根CA私钥 (RSA 4096)..."
    openssl genrsa -out private/root_ca.key.pem 4096
    
    # 生成CA证书
    echo -e "${YELLOW}[INFO]${NC} 生成根CA证书..."
    
    # 构建 subject 字符串
    SUBJECT="/C=${CA_CONFIG[CA_C]}/ST=${CA_CONFIG[CA_ST]}/L=${CA_CONFIG[CA_L]}/O=${CA_CONFIG[CA_O]}/OU=${CA_CONFIG[CA_OU]}/CN=${CA_CONFIG[CA_CN]}/emailAddress=${CA_CONFIG[CA_EMAIL]}"
    
    envStr=$(uname -a)
    if [[ $envStr =~ 'MINGW' ]]; then
        # MinGW 环境需要双斜杠
        SUBJECT="/${SUBJECT}"
    fi
    
    openssl req -config openssl_root_ca.conf -subj "$SUBJECT" -new -x509 -days 36500 -sha256 -extensions root_ca -key private/root_ca.key.pem -out cert/root_ca.cert.pem
    
    # 拷贝一个crt格式，方便Windows系统导入
    cp ./cert/root_ca.cert.pem ./cert/root_ca.cert.crt
    
    cd ../../
    echo -e "${GREEN}[SUCCESS]${NC} 根CA证书生成成功！"
    echo -e "${CYAN}[INFO]${NC} 证书位置: certificate-signature/root/cert/root_ca.cert.crt"
}

# 生成中间CA证书
function generate_intermediate_ca() {
    echo -e "${YELLOW}[INFO]${NC} 开始生成中间CA证书..."
    
    if [ ! -d "./certificate-signature/root" ]; then
        echo -e "${RED}[ERROR]${NC} 请先生成根证书！"
        return 1
    fi
    
    cd ./certificate-signature
    rm -rf ./intermediate
    mkdir intermediate
    cd intermediate
    
    # 创建目录结构
    mkdir cert chain csr private signed_certs
    touch index.txt index.txt.attr serial
    echo 0001 >serial
    echo unique_subject = no >index.txt.attr
    
    # 拷贝配置文件
    cp ../../openssl_intermediate_ca.conf ./openssl_intermediate_ca.conf
    
    # 生成中间CA私钥 (ECDSA P-256)
    echo -e "${YELLOW}[INFO]${NC} 生成中间CA私钥 (ECDSA P-256)..."
    openssl ecparam -genkey -name prime256v1 -out private/intermediate_ca.key.pem
    
    # 生成CSR
    echo -e "${YELLOW}[INFO]${NC} 生成中间CA证书签名请求..."
    
    # 构建 subject 字符串
    SUBJECT="/C=${CA_CONFIG[CA_C]}/ST=${CA_CONFIG[CA_ST]}/L=${CA_CONFIG[CA_L]}/O=${CA_CONFIG[CA_O]}/OU=${CA_CONFIG[CA_OU]}/CN=${CA_CONFIG[CA_INTERMEDIATE_CN]}/emailAddress=${CA_CONFIG[CA_EMAIL]}"
    
    envStr=$(uname -a)
    if [[ $envStr =~ 'MINGW' ]]; then
        # MinGW 环境需要双斜杠
        SUBJECT="/${SUBJECT}"
    fi
    
    openssl req -config openssl_intermediate_ca.conf -subj "$SUBJECT" -new -sha256 -key private/intermediate_ca.key.pem -out csr/intermediate_ca.csr.pem
    
    # 使用根证书签发
    echo -e "${YELLOW}[INFO]${NC} 使用根CA签发中间CA证书..."
    cd ../root
    openssl ca -batch -config openssl_root_ca.conf -extensions intermediate_ca -days 3600 -notext -md sha256 -in ../intermediate/csr/intermediate_ca.csr.pem -out ../intermediate/cert/intermediate_ca.cert.pem
    
    # 验证证书
    echo -e "${YELLOW}[INFO]${NC} 验证中间CA证书..."
    openssl verify -CAfile cert/root_ca.cert.pem ../intermediate/cert/intermediate_ca.cert.pem
    
    # 创建证书链
    cd ../intermediate
    cat cert/intermediate_ca.cert.pem ../root/cert/root_ca.cert.pem >chain/chain.cert.pem
    
    # 拷贝一个crt格式，方便Windows系统导入
    cp ./cert/intermediate_ca.cert.pem ./cert/intermediate_ca.cert.crt
    cp ./chain/chain.cert.pem ./chain/chain.cert.crt
    
    cd ../../
    echo -e "${GREEN}[SUCCESS]${NC} 中间CA证书生成成功！"
    echo -e "${CYAN}[INFO]${NC} 证书位置: certificate-signature/intermediate/cert/intermediate_ca.cert.crt"
    echo -e "${CYAN}[INFO]${NC} 证书链位置: certificate-signature/intermediate/chain/chain.cert.crt"
}

# 生成站点证书
function generate_web_certificate() {
    echo -e "${YELLOW}[INFO]${NC} 开始生成站点证书..."
    
    if [ ! -d "./certificate-signature/intermediate" ]; then
        echo -e "${RED}[ERROR]${NC} 请先生成根证书和中间CA证书！"
        return 1
    fi
    
    cd ./certificate-signature
    rm -rf ./server
    mkdir server
    cd server
    
    # 拷贝配置文件
    cp ../../openssl_csr.conf ./openssl_csr.conf
    
    # 生成站点证书私钥 (ECDSA P-256)
    echo -e "${YELLOW}[INFO]${NC} 生成站点证书私钥 (ECDSA P-256)..."
    openssl ecparam -genkey -name prime256v1 -out server.key.pem
    
    # 生成CSR（携带扩展信息，包括SAN）
    echo -e "${YELLOW}[INFO]${NC} 生成站点证书签名请求（包含SAN扩展）..."
    
    # 构建 subject 字符串（站点证书使用通配符域名）
    SUBJECT="/C=${CA_CONFIG[CA_C]}/ST=${CA_CONFIG[CA_ST]}/L=${CA_CONFIG[CA_L]}/O=${CA_CONFIG[CA_O]}/OU=IT Services/CN=*.internal.local/emailAddress=${CA_CONFIG[CA_EMAIL]}"
    
    envStr=$(uname -a)
    if [[ $envStr =~ 'MINGW' ]]; then
        # MinGW 环境需要双斜杠
        SUBJECT="/${SUBJECT}"
    fi
    
    # -reqexts v3_req 确保将扩展信息（包括SAN）包含到CSR中
    openssl req -config openssl_csr.conf -reqexts v3_req -subj "$SUBJECT" -new -sha256 -key server.key.pem -out server.csr.pem
    
    # 使用中间CA签发（从CSR复制扩展信息）
    echo -e "${YELLOW}[INFO]${NC} 使用中间CA签发站点证书（从CSR复制SAN配置）..."
    cd ../intermediate
    openssl ca -batch -config openssl_intermediate_ca.conf -extensions server_cert -days 1800 -notext -md sha256 -in ../server/server.csr.pem -out ../server/server.cert.pem
    
    # 验证证书
    echo -e "${YELLOW}[INFO]${NC} 验证站点证书..."
    openssl verify -CAfile chain/chain.cert.pem ../server/server.cert.pem
    
    # 创建完整证书链
    cd ../server
    cat server.cert.pem ../intermediate/chain/chain.cert.pem >server_fullchain.cert.pem
    cp server_fullchain.cert.pem server_fullchain.cert.crt
    
    cd ../../
    echo -e "${GREEN}[SUCCESS]${NC} 站点证书生成成功！"
    echo -e "${CYAN}[INFO]${NC} 证书位置: certificate-signature/server/server_fullchain.cert.crt"
    echo -e "${CYAN}[INFO]${NC} 私钥位置: certificate-signature/server/server.key.pem"
}

# 生成所有证书
function generate_all() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              开始生成所有证书                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 清理旧文件
    echo -e "${YELLOW}[INFO]${NC} 清理旧的证书文件..."
    rm -rf ./certificate-signature
    mkdir certificate-signature
    
    # 加载配置
    load_config
    
    # 处理配置
    generate_config
    echo ""
    
    # 生成根CA
    generate_root_ca
    echo ""
    
    # 生成中间CA
    generate_intermediate_ca
    echo ""
    
    # 生成站点证书
    generate_web_certificate
    echo ""
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              所有证书生成完成！                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
}

# 查看证书信息
function view_certificates() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              证书信息查看                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 检查根CA
    if [ -f "./certificate-signature/root/cert/root_ca.cert.pem" ]; then
        echo -e "${GREEN}[✓]${NC} 根CA证书 ${YELLOW}(RSA 4096)${NC}:"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        openssl x509 -noout -subject -issuer -dates -in ./certificate-signature/root/cert/root_ca.cert.pem
        echo -e "${CYAN}  公钥算法:${NC}" $(openssl x509 -noout -text -in ./certificate-signature/root/cert/root_ca.cert.pem | grep "Public Key Algorithm" | sed 's/^[ \t]*//')
        echo ""
    else
        echo -e "${RED}[✗]${NC} 根CA证书: 不存在"
        echo ""
    fi
    
    # 检查中间CA
    if [ -f "./certificate-signature/intermediate/cert/intermediate_ca.cert.pem" ]; then
        echo -e "${GREEN}[✓]${NC} 中间CA证书 ${YELLOW}(ECDSA P-256)${NC}:"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        openssl x509 -noout -subject -issuer -dates -in ./certificate-signature/intermediate/cert/intermediate_ca.cert.pem
        echo -e "${CYAN}  公钥算法:${NC}" $(openssl x509 -noout -text -in ./certificate-signature/intermediate/cert/intermediate_ca.cert.pem | grep "Public Key Algorithm" | sed 's/^[ \t]*//')
        echo ""
    else
        echo -e "${RED}[✗]${NC} 中间CA证书: 不存在"
        echo ""
    fi
    
    # 检查站点证书
    if [ -f "./certificate-signature/server/server.cert.pem" ]; then
        echo -e "${GREEN}[✓]${NC} 站点证书 ${YELLOW}(ECDSA P-256)${NC}:"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        openssl x509 -noout -subject -issuer -dates -in ./certificate-signature/server/server.cert.pem
        echo -e "${CYAN}  公钥算法:${NC}" $(openssl x509 -noout -text -in ./certificate-signature/server/server.cert.pem | grep "Public Key Algorithm" | sed 's/^[ \t]*//')
        echo ""
        echo -e "${CYAN}[INFO]${NC} SAN (Subject Alternative Names):"
        openssl x509 -noout -text -in ./certificate-signature/server/server.cert.pem | grep -A 5 "Subject Alternative Name"
        echo ""
    else
        echo -e "${RED}[✗]${NC} 站点证书: 不存在"
        echo ""
    fi
}

# 清理证书
function clean_certificates() {
    echo -e "${YELLOW}[WARNING]${NC} 此操作将删除所有已生成的证书！"
    read -p "确认删除? (y/n): " confirm
    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
        rm -rf ./certificate-signature
        echo -e "${GREEN}[SUCCESS]${NC} 所有证书已清理"
    else
        echo -e "${CYAN}[INFO]${NC} 操作已取消"
    fi
}

# 暂停函数
function pause() {
    echo ""
    read -p "按回车键继续..."
}

# 主程序
function main() {
    # 预加载配置（不执行替换，只加载到内存）
    load_config
    
    while true; do
        show_banner
        show_menu
        
        read -p "请输入选项 [0-7]: " choice
        echo ""
        
        case $choice in
            1)
                generate_all
                pause
                ;;
            2)
                generate_config
                generate_root_ca
                pause
                ;;
            3)
                generate_intermediate_ca
                pause
                ;;
            4)
                generate_web_certificate
                pause
                ;;
            5)
                view_certificates
                pause
                ;;
            6)
                view_config
                pause
                ;;
            7)
                clean_certificates
                pause
                ;;
            0)
                echo -e "${GREEN}感谢使用！再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} 无效的选项，请重新选择"
                pause
                ;;
        esac
    done
}

# 运行主程序
main

