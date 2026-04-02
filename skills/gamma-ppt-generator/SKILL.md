---
name: gamma-ppt-generator
description: "Expert guide for generating professional AI-powered presentations using Gamma API (gamma.app) in enterprise network environments. Use this skill when users want to: (1) automate PPT/presentation generation from Markdown scripts via Gamma API, (2) bypass corporate proxy SSL interception and Cloudflare bot detection when calling API endpoints, (3) set up a local HTTP proxy using curl.exe for browser-to-API communication. Triggers on mentions of 'gamma', 'PPT生成', 'presentation automation', 'API proxy', or 'Cloudflare 1010'."
version: "1.0.0"
---

# Gamma PPT 自动化生成专家指南

本技能提供在企业内网环境下，通过 Gamma API 自动生成演示文稿的完整工程方案，包含对三大典型障碍（CORS、企业代理 SSL 截断、Cloudflare bot 检测）的系统性解法。

## 关键文件位置

| 文件 | 路径 | 用途 |
|------|------|------|
| `proxy_server.py` | `c:\Users\leech\VibeCoding\HW\Mindspore\proxy_server.py` | 本地 curl.exe 代理服务器（**核心工具**） |
| `gamma_ppt_tool.html` | `c:\Users\leech\VibeCoding\HW\Mindspore\gamma_ppt_tool.html` | 浏览器端 UI 工具 |
| `submit_to_gamma.py` | `c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen\submit_to_gamma.py` | 纯 Python CLI 提交脚本（备用） |
| `ppt_gen/PASTE_THIS.md` | `c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen\PASTE_THIS.md` | 最新合并 PPT 脚本（可直接粘贴） |
| `ppt_gen/output_ch*.md` | 同目录 | 按章节分开的源文件（正确 UTF-8 编码） |

## Gamma API 核心参数

```
Base URL : https://public-api.gamma.app/v1.0
Endpoint : POST /generations
Auth     : Header X-API-KEY: <key>
Key 位置 : C:\Users\leech\VibeCoding\API key.md  （#Gamma 节）
```

### 请求体结构

```json
{
  "inputText":    "<Markdown 脚本，以 --- 分隔幻灯片>",
  "textMode":     "preserve",
  "format":       "presentation",
  "cardSplit":    "inputTextBreaks",
  "exportAs":     "pptx",
  "textOptions":  { "language": "zh-cn" },
  "imageOptions": {
    "source": "aiGenerated",
    "model":  "imagen-3-flash",
    "style":  "Academic technical architecture diagram..."
  },
  "cardOptions":  { "dimensions": "16x9" }
}
```

### 支持的图片模型（imageOptions.model）

| 模型名 | 显示名 | Credits/张 | 适用场景 |
|--------|--------|-----------|---------|
| `imagen-3-flash` | Imagen 3 Fast | 2 | 快速生成，节省 Credits |
| `imagen-4-pro` | Imagen 4 | 20 | 较高质量 |
| `gemini-3-pro-image` | Nano Banana Pro | 20 | 均衡 |
| `gemini-3.1-flash-image-mini` | NB2 Mini | 34 | 高质量 |
| `gemini-3.1-flash-image` | Nano Banana 2 | 50 | 最高质量（推荐学术场景） |
| `ideogram-v3-quality` | Ideogram 3 Quality | 45 | 艺术风格图像 |

### 轮询接口

```
GET /v1.0/generations/{generationId}
返回 status: pending / completed / failed
completed 后包含 gammaUrl 和 exportUrl
```

---

## 三大网络障碍与解法

### 障碍 1：CORS（浏览器跨域拦截）

**现象**：HTML 工具从 `file://` 协议调用 `https://` API，浏览器 1 秒内报 `Failed to fetch`

**根因**：浏览器安全策略禁止从 `file://` 发起跨域请求

**解法**：通过 `proxy_server.py` 将 HTML 从 `localhost:9090` 提供服务，JS 请求为同源请求，绕过 CORS

### 障碍 2：企业代理 SSL 截断

**现象**：Python `requests` / `urllib` 报 `SSLEOFError: EOF occurred in violation of protocol`

**根因**：企业内网代理做 SSL 深度检查（DPI），拦截并修改 TLS 握手，导致 Python 的 `certifi` CA 库验证失败

**关键发现**：`proxies={"http": "", "https": ""}` 在 Windows 上**无法**绕过注册表代理，必须显式传递且仍然无效；`requests.Session` 也无法彻底绕过

**解法**：使用 `curl.exe`（Windows 内置，使用 Schannel/WinSSL）替代 Python `urllib` 发出实际请求

```python
# 在代理服务器中使用 subprocess 调用 curl.exe
result = subprocess.run(
    ["curl.exe", "-s", "-X", method, url, "--data-binary", "@-", ...],
    input=body, capture_output=True, timeout=35
)
```

### 障碍 3：Cloudflare Bot 检测（错误 1010）

**现象**：请求返回 `403 error code: 1010`，被 Cloudflare 判断为机器人

**根因**：Cloudflare 使用 **JA3 TLS 指纹**区分 Python `ssl` 模块与真实浏览器，Python 的 TLS 握手特征在黑名单中

**关键发现**：`curl.exe`（Windows Schannel TLS）的指纹**不在** Cloudflare 黑名单中

**解法**：代理服务器使用 curl.exe 时附加浏览器级别的 HTTP 请求头：

```
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0
Origin: https://gamma.app
Referer: https://gamma.app/
Sec-Fetch-Site: same-site
Sec-Fetch-Mode: cors
```

---

## 脚本编写规范

### Markdown 分页格式

```markdown
## 幻灯片标题

内容正文...

---

## 下一张幻灯片标题

内容...
```

- **`---`** 是分页符，Gamma 按此切割幻灯片
- **`textMode: "preserve"`** 保持原始内容，不让 Gamma AI 改写
- 建议单张幻灯片内容 200-600 字，避免因内容过长被 Gamma 自动截断

### 章节文件组织（大型脚本推荐）

```
ppt_gen/
├── output_ch0_ch1.md   # 第0-1章
├── output_ch2.md       # 第2章
├── output_ch3.md       # 第3章（以此类推）
└── PASTE_THIS.md       # 由 Python 合并生成（UTF-8，无 BOM）
```

**合并命令**（关键：用 Python 而不是 cmd copy，避免 BOM 乱码）：

```python
# 生成 PASTE_THIS.md
files = ["output_ch0_ch1.md", "output_ch2.md", "output_ch3.md", ...]
base = r"c:\...\ppt_gen"
parts = []
for f in files:
    with open(os.path.join(base, f), encoding="utf-8-sig") as fp:  # utf-8-sig 剥离 BOM
        parts.append(fp.read().strip())
merged = "\n\n---\n\n".join(parts)
with open(os.path.join(base, "PASTE_THIS.md"), "w", encoding="utf-8") as fp:
    fp.write(merged)
```

> ⚠️ **禁止使用 `cmd /c copy /b`**：会将各文件的 UTF-8 BOM 字节（`0xEF BB BF`）拼接到文件中间，造成乱码

---

## 架构图

```
用户操作 (浏览器)
    │  打开 http://localhost:9090/
    │
    ▼
Python proxy_server.py (port 9090)
    │  提供 gamma_ppt_tool.html（BASE_URL 已替换为 /gamma/v1.0）
    │  接收 /gamma/* 请求
    │
    ▼  subprocess.run(["curl.exe", ...])
Windows curl.exe (Schannel TLS)
    │  User-Agent: Chrome  |  Origin: gamma.app
    │  X-API-KEY: sk-gamma-...
    │
    ▼
Cloudflare (public-api.gamma.app)
    │  ✅ TLS 指纹通过 | ✅ 请求头合规
    │
    ▼
Gamma API
    └─ 返回 generationId → 浏览器轮询 → 完成后提供下载链接
```

---

## 错误速查表

| 错误信息 | 根因 | 解法 |
|---------|------|------|
| `Failed to fetch`（1秒内） | CORS：file:// 协议跨域限制 | 启动 proxy_server.py，从 localhost 访问 |
| `Failed to fetch`（秒级后） | CORS：localhost 向 Gamma 跨域 | proxy_server.py 已处理，确保 HTML 已替换 BASE_URL |
| `SSLEOFError: EOF occurred` | 企业代理 SSL DPI 拦截 Python TLS | 改用 curl.exe 发出请求 |
| `403 error code: 1010` | Cloudflare JA3 指纹检测到 Python | 改用 curl.exe + 浏览器请求头 |
| `401 Invalid API key` | API Key 无效或过期 | 检查 `C:\Users\leech\VibeCoding\API key.md` |
| Markdown 乱码 | `cmd /b copy` 拼接了多个 BOM 头 | 改用 Python `utf-8-sig` 读取后重新写出 |
| `KeyboardInterrupt` in poll | 用户手动中断轮询 | 运行 `check_result.py` 继续轮询已提交的 generationId |
