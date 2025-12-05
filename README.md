## 自签证书脚本

将自签证书相关流程自动化，只需要少数几个操作即可生成带有中间 CA 的自签证书与 CA 证书

### 密钥算法说明

本项目采用现代化的密钥算法组合，兼顾安全性与性能：

| 证书类型 | 密钥算法 | 说明 |
|---------|---------|------|
| **根CA证书** | RSA 4096 | 最大兼容性，适合长期信任的根证书 |
| **中间CA证书** | ECDSA P-256 | 现代化算法，密钥更小，性能更优 |
| **站点证书** | ECDSA P-256 | 现代化算法，适合HTTPS服务 |

**优势**：
- ✅ ECDSA P-256 相比 RSA 密钥更小（仅256位 vs 4096位）
- ✅ ECDSA 签名和验证速度更快
- ✅ 降低TLS握手延迟
- ✅ 所有现代浏览器均支持 ECDSA P-256

## 使用方法

本项目提供了统一的菜单式入口脚本，操作简单方便。

### 1. 配置站点证书信息（必须）

**修改文件 `openssl_csr.conf` 中的 `[alt_names]` 段，配置站点证书的域名与 IP**

⚠️ **重要**：这是配置站点证书 SAN（Subject Alternative Names）的正确位置。修改站点证书的域名/IP时：
- ✅ **只需修改** `openssl_csr.conf` 中的 `[alt_names]`
- ✅ **无需修改** 中间CA配置（`openssl_intermediate_ca.conf`）
- ✅ **无需重新签发** 中间CA证书
- ✅ **只需重新生成** 站点证书即可（菜单选项 [4]）

示例配置（openssl_csr.conf 第41-50行左右）：

```ini
[alt_names]
DNS.1 = localhost
DNS.2 = *.local
DNS.3 = *.dev
DNS.4 = *.internal.local
DNS.5 = example.com
DNS.6 = *.example.com
IP.1 = 127.0.0.1
IP.2 = 192.168.1.1
```

**配置说明：**
- `DNS.x` - 配置域名，支持通配符（如 `*.example.com`）
- `IP.x` - 配置 IP 地址
- 序号必须连续（DNS.1, DNS.2, DNS.3...）

**架构说明：**
- 站点证书的SAN配置在CSR（证书签名请求）中携带
- 中间CA签发时会从CSR中复制这些扩展信息到最终证书
- 这样设计符合PKI标准，职责分离更清晰

### 2. 配置CA基本信息（推荐）

修改默认配置文件 `openssl_config_default.properties` 以自定义您的证书颁发机构信息。

**主要配置项：**

| 配置项 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `CA_C` | 国家代码（2位字母） | CN | US, UK, JP |
| `CA_ST` | 省份/州 | Beijing | California, Tokyo |
| `CA_L` | 城市 | Beijing | San Francisco |
| `CA_O` | 组织名称 | Internal Certificate Authority | YourCompany Inc |
| `CA_OU` | 组织单位/部门 | Certificate Authority Division | IT Department |
| `CA_CN` | 根CA名称 | Internal Root CA | YourCompany Root CA |
| `CA_INTERMEDIATE_CN` | 中间CA名称 | Internal Intermediate CA | YourCompany Intermediate CA |
| `CA_EMAIL` | 联系邮箱 | ca-admin@internal.local | admin@example.com |

**可选配置项（高级）：**

| 配置项 | 说明 | 用途 |
|--------|------|------|
| `CA_CRL_URL` | CRL分发点URL | 证书吊销列表（生产环境建议配置） |
| `CA_OCSP_URL` | OCSP响应器URL | 在线证书状态协议（生产环境建议配置） |

**配置示例：**

```properties
CA_C=US
CA_ST=California
CA_L=San Francisco
CA_O=TechCorp Inc
CA_OU=Security Operations
CA_CN=TechCorp Internal Root CA
CA_INTERMEDIATE_CN=TechCorp Internal Issuing CA
CA_EMAIL=security@techcorp.com
```

具体配置含义，请参考：[opensslconf 配置](https://www.phildev.net/ssl/opensslconf.html)中的 req_distinguished_name 段

### 3. 赋予可执行权限

如果您的执行环境是 Linux/Unix/WSL/Git Bash，请赋予脚本可执行权限：

```bash
chmod +x start.sh
```

**注意**：Windows 用户请使用 Git Bash、WSL 或其他 Bash 环境运行此脚本。

### 4. 运行脚本

```bash
./start.sh
```

### 5. 菜单功能说明

运行后会显示交互式菜单，根据提示选择相应功能：

| 选项 | 功能说明 | 适用场景 |
|------|----------|----------|
| **[1]** | 生成所有证书 | 首次使用，一键生成根CA + 中间CA + 站点证书 |
| **[2]** | 仅生成根CA证书 | 单独重新生成根CA证书 |
| **[3]** | 仅生成中间CA证书 | 单独重新生成中间CA证书（需先有根CA） |
| **[4]** | 仅生成站点证书 | 单独重新生成站点证书（需先有根CA和中间CA） |
| **[5]** | 查看当前证书信息 | 查看已生成证书的主题、颁发者、有效期、算法等信息 |
| **[6]** | 查看CA配置信息 | 查看当前的CA配置（组织信息、名称等） |
| **[7]** | 清理所有生成的证书 | 删除所有已生成的证书文件（需确认） |
| **[0]** | 退出系统 | 退出脚本程序 |

**提示**：证书生成过程已全自动化，无需手动确认，坐等完成即可。

### 证书类型验证

生成完成后，可以使用以下命令验证证书类型：

```bash
# 验证根CA证书（应显示 CA:TRUE）
openssl x509 -in certificate-signature/root/cert/root_ca.cert.pem -noout -text | grep "CA:"

# 验证中间CA证书（应显示 CA:TRUE, pathlen:0）
openssl x509 -in certificate-signature/intermediate/cert/intermediate_ca.cert.pem -noout -text | grep "CA:"

# 验证站点证书（应显示 CA:FALSE）
openssl x509 -in certificate-signature/server/server.cert.pem -noout -text | grep "CA:"
```

### 执行环境说明

- **推荐环境**: Linux、Unix、macOS、Windows WSL、Git Bash
- **Cmder 环境注意**: 可能存在 `find` 命令冲突，请确保使用 MinGW 的 find 而非 DOS 的 find 命令

## 结果文件说明

### 根证书 (RSA 4096)

**位置**：`certificate-signature/root/`

- `cert/root_ca.cert.crt` - 根证书（需分发给客户端并导入受信任的根证书列表）
- `private/root_ca.key.pem` - 根CA私钥（**请妥善保管**）
- **有效期**：100年

### 中间CA证书 (ECDSA P-256)

**位置**：`certificate-signature/intermediate/`

- `cert/intermediate_ca.cert.pem` 或 `cert/intermediate_ca.cert.crt` - 中间CA证书
- `private/intermediate_ca.key.pem` - 中间CA私钥（**请妥善保管**）
- `chain/chain.cert.pem` 或 `chain/chain.cert.crt` - 完整证书链（中间CA + 根CA）
- **有效期**：约10年

### 站点证书 (ECDSA P-256)

**位置**：`certificate-signature/server/`

- `server_fullchain.cert.crt` 或 `server_fullchain.cert.pem` - 完整证书链（内容相同，扩展名不同）
- `server.key.pem` - 站点私钥（**配置HTTPS时需要**）
- **有效期**：约5年

### HTTPS 服务器配置

配置 HTTPS 服务时需要使用：
- **证书文件**：`certificate-signature/server/server_fullchain.cert.crt`
- **私钥文件**：`certificate-signature/server/server.key.pem`

示例（Nginx）：
```nginx
ssl_certificate /path/to/server_fullchain.cert.crt;
ssl_certificate_key /path/to/server.key.pem;
```
