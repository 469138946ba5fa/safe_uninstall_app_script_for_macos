# safe_uninstall_app_script_for_macos
由于没钱购买卸载软件，我写了一个能满足自己安全卸载macos应用程序需求的脚本


![Watchers](https://img.shields.io/github/watchers/469138946ba5fa/safe_uninstall_app_script_for_macos) ![Stars](https://img.shields.io/github/stars/469138946ba5fa/safe_uninstall_app_script_for_macos) ![Forks](https://img.shields.io/github/forks/469138946ba5fa/safe_uninstall_app_script_for_macos) ![Vistors](https://visitor-badge.laobi.icu/badge?page_id=469138946ba5fa.safe_uninstall_app_script_for_macos) ![LICENSE](https://img.shields.io/badge/license-CC%20BY--SA%204.0-green.svg)
<a href="https://star-history.com/#469138946ba5fa/safe_uninstall_app_script_for_macos&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=469138946ba5fa/safe_uninstall_app_script_for_macos&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=469138946ba5fa/safe_uninstall_app_script_for_macos&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=469138946ba5fa/safe_uninstall_app_script_for_macos&type=Date" />
  </picture>
</a>
## macOS 应用安全卸载脚本说明

这是一个依赖全应用名（App Name）进行残留清理的 macOS 应用卸载脚本。依赖全应用名可能也是一个缺陷，不过目前满足我的需求是够用的。

### 脚本特点

  * 支持 **`dry-run` 模式**（仅预览要删除的文件，不执行实际删除操作）。
  * 覆盖 **常见的用户级和系统级残留目录**。
  * 使用安全的 **`find + print0` 机制**，有效避免文件名中包含空格或特殊字符时的问题。
  * **分步骤输出**，清晰展示整个卸载和清理流程。
  * 所有的删除动作都将写入日志文件：`~/uninstall.log`。

### 目录结构

项目工作目录如下：
```
.
└── safe_uninstall.sh          # 安全卸载macos应用程序需求的脚本
```

### 使用方法

```bash
chmod -v a+x ./safe_uninstall.sh
./safe_uninstall.sh <AppName> [可选参数]
```

| 参数 | 描述 |
| :--- | :--- |
| `<AppName>` | 必填，要卸载的应用名称 (如 `v2rayN`)。|
| `--dry-run` | 可选，开启预览模式，不执行删除。|

### 示例

**比如我要卸载 `v2rayN.app` 的步骤示例：**

1.  **仅预览** 要删除的文件 (安全检查)：
    ```bash
    ./safe_uninstall.sh v2rayN --dry-run
    ```
2.  **实际执行删除** 操作：
    ```bash
    ./safe_uninstall.sh v2rayN
    ```
