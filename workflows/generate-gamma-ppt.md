---
description: 使用 Gamma API 自动生成演示 PPT，通过本地代理服务器绕过企业内网 Cloudflare 和 SSL 限制
---

# Gamma PPT 自动化生成工作流

> **适用场景**：需要将 Markdown 脚本一键生成为专业演示文稿（PPTX），并带 AI 配图

## 前置条件

- API Key 已保存：`C:\Users\leech\VibeCoding\API key.md`（`#Gamma` 节）
- 代理脚本已就绪：`c:\Users\leech\VibeCoding\HW\Mindspore\proxy_server.py`
- HTML 工具已就绪：`c:\Users\leech\VibeCoding\HW\Mindspore\gamma_ppt_tool.html`
- Python 3.x 已安装，`curl.exe` 可用（Windows 内置）

---

## Step 1：准备 Markdown 脚本

编写或整理演示脚本，每张幻灯片用 `---` 分隔：

```markdown
## 幻灯片标题

内容...

---

## 下一张

内容...
```

如果脚本分多个章节文件（`output_ch*.md`），运行以下命令合并（**必须用 Python，禁止 cmd copy**）：

```powershell
cd "c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen"
python -c "
import os
files = ['output_ch0_ch1.md','output_ch2.md','output_ch3.md','output_ch4.md','output_ch5.md']
base = r'c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen'
parts = []
for f in files:
    with open(os.path.join(base, f), encoding='utf-8-sig') as fp:
        parts.append(fp.read().strip())
merged = '\n\n---\n\n'.join(parts)
with open(os.path.join(base, 'PASTE_THIS.md'), 'w', encoding='utf-8') as fp:
    fp.write(merged)
print(f'Done: {len(merged)} chars')
"
```

生成文件：`ppt_gen/PASTE_THIS.md`

---

## Step 2：启动本地代理服务器

// turbo
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\Users\leech\VibeCoding\HW\Mindspore'; python proxy_server.py"
```

代理服务器自动：
- 启动在 `http://localhost:9090/`
- 用 `curl.exe` 转发 API 请求（绕过 Cloudflare 1010 + SSL 截断）
- 将 HTML 工具的 `BASE_URL` 替换为本地地址（解决 CORS）
- **自动打开浏览器**

---

## Step 3：在浏览器工具中提交

1. 浏览器已打开 `http://localhost:9090/`（若未自动打开，手动输入）
2. 打开 `PASTE_THIS.md`，**Ctrl+A → Ctrl+C** 全选复制
3. 粘贴到工具的脚本文本框
4. 选择图片模型：
   - 省钱快速：**Imagen 3 Fast**（2 Credits/张）
   - 学术高质：**Nano Banana 2**（50 Credits/张）
5. 确认 API Key 已填写（工具会预置）
6. 点击 **"🚀 提交到 Gamma · 一键生成"**

---

## Step 4：等待并获取结果

工具会自动轮询状态（每 5 秒），约 2-5 分钟后：
- 显示 `🎉 生成完成！`
- 出现 **"在 Gamma 中查看"** 链接（点击即可在线演示）
- 出现 **"下载 PPTX"** 链接（下载到本地）

若中途关闭浏览器，可用以下命令继续轮询：

```powershell
# 修改 check_result.py 中的 GEN_ID 为实际的 generationId
cd "c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen"
python check_result.py
```

---

## Step 5：清理与归档

```powershell
# 停止代理服务器（在代理窗口按 Ctrl+C）
# 下载完成后可删除临时文件
Remove-Item "c:\Users\leech\VibeCoding\HW\Mindspore\ppt_gen\PASTE_THIS.md" -ErrorAction SilentlyContinue
```

---

## 常见错误

| 错误 | 解法 |
|------|------|
| `Failed to fetch`（1秒内） | 确认代理服务器已启动，从 `localhost:9090` 而非 `file://` 访问 |
| `403 error code: 1010` | 重启代理服务器（确保使用 v2 curl 版本） |
| `SSLEOFError` | 检查 proxy_server.py 是否使用 curl.exe（非 urllib） |
| 脚本乱码 | 用 Python utf-8-sig 重新合并，禁止 `cmd copy /b` |
| 脚本长度只有 ~3631 字符 | 只粘贴了单个章节，需粘贴完整的 PASTE_THIS.md |

---

## 参考技能

- 使用本工作流前，请先阅读：[gamma-ppt-generator SKILL](..\skills\gamma-ppt-generator\SKILL.md)
