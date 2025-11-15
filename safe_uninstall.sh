#!/bin/bash
#
# safe_uninstall.sh
#
# 一个依赖应用名的 macOS 应用卸载脚本。
# 特点：
#   - 支持 dry-run 模式（仅预览，不删除）
#   - 覆盖常见的用户级和系统级残留目录
#   - 使用安全的 find + print0 机制，避免空格/特殊字符问题
#   - 分步骤输出，清晰展示卸载流程
#   - 删除动作写入日志 ~/uninstall.log
#
# 使用方法:
#   ./safe_uninstall.sh <AppName> [--dry-run]
#
# 示例卸载 v2rayN.app:
#   ./safe_uninstall.sh v2rayN --dry-run   # 仅预览
#   ./safe_uninstall.sh v2rayN             # 实际删除
#

VERSION="1.1"
LOGFILE="$HOME/uninstall.log"

# 保存并修改 IFS 以正确处理带空格的文件名
IFS_BAK=$IFS
IFS=$'\n'

APP_NAME="$1"   # 第一个参数：应用名称（不带 .app 后缀）
MODE="$2"       # 第二个参数：可选 --dry-run

# 参数检查
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<EOF
一个依赖应用名的 macOS 应用卸载脚本。
Usage: $0 <AppName> [--dry-run]

Options:
  -h, --help     显示本帮助信息
  -v, --version  显示脚本版本
  --dry-run      仅预览将要删除的文件，不实际删除

Examples uninstall v2rayN.app:
  $0 v2rayN           卸载 v2rayN 应用及残留
  $0 v2rayN --dry-run 仅预览 v2rayN 应用及残留不会卸载删除
EOF
  exit 0
fi

if [[ "$1" == "-v" || "$1" == "--version" ]]; then
  echo "safe_uninstall.sh version $VERSION (last updated: 2025-10-09)"
  exit 0
fi

if [[ "${APP_NAME}x" = "x" ]]; then
  echo "Usage: $0 <AppName> [--dry-run]"
  exit 1
fi

echo "--- 开始对应用程序 [${APP_NAME}] 进行彻底卸载 ---"
echo "$(date) 开始卸载 [${APP_NAME}] 模式: ${MODE}" >> "$LOGFILE"

# ---------------------------------------------------------
# 函数：safe_find_and_delete
# 功能：在指定目录中查找包含 APP_NAME 的文件/目录，并删除
# ---------------------------------------------------------
safe_find_and_delete() {
    local search_path=$1
    local search_name=$2
    echo -e "\n正在搜索目录: ${search_path}"

    local files_to_delete=()
    while IFS= read -r -d $'\0' file; do
        files_to_delete+=("$file")
    done < <(sudo find "${search_path}" -iname "*${search_name}*" -maxdepth 4 -print0 2>/dev/null)

    if [ ${#files_to_delete[@]} -gt 0 ]; then
        echo "发现以下相关文件/文件夹:"
        printf "  - %s\n" "${files_to_delete[@]}"
        if [[ "$MODE" != "--dry-run" ]]; then
            for f in "${files_to_delete[@]}"; do
                if ! sudo rm -frv "$f" 2>>"$LOGFILE"; then
                    echo "[提示] 无法删除 $f (可能受 macOS SIP/TCC 保护)"
                    echo "$(date) 删除失败: $f (权限保护)" >> "$LOGFILE"
                else
                    echo "$(date) 删除成功: $f" >> "$LOGFILE"
                fi
            done
        else
            echo "[dry-run] 未执行删除"
            for f in "${files_to_delete[@]}"; do
                echo "$(date) 预览删除: $f" >> "$LOGFILE"
            done
        fi
    else
        echo "在该目录中未找到相关文件。"
    fi
}

# ---------------------------------------------------------
# 步骤 1: 终止相关进程
# ---------------------------------------------------------
echo -e "\n[步骤 1/7] 正在尝试终止 ${APP_NAME} 相关进程..."
if pgrep -f "${APP_NAME}" > /dev/null; then
    if [[ "$MODE" != "--dry-run" ]]; then
        sudo pkill -f "${APP_NAME}"
        echo "进程已终止。"
        echo "$(date) 终止进程: ${APP_NAME}" >> "$LOGFILE"
    else
        echo "[dry-run] 将终止进程: ${APP_NAME}"
        echo "$(date) 预览终止进程: ${APP_NAME}" >> "$LOGFILE"
    fi
else
    echo "未找到正在运行的 ${APP_NAME} 进程。"
fi

# ---------------------------------------------------------
# 步骤 2: 删除主应用程序
# ---------------------------------------------------------
echo -e "\n[步骤 2/7] 正在检查并删除主程序..."
app_candidates=($(find /Applications ~/Applications -maxdepth 1 -iname "${APP_NAME}.app" 2>/dev/null))
if [ ${#app_candidates[@]} -gt 1 ]; then
    echo "发现多个同名应用:"
    printf "  - %s\n" "${app_candidates[@]}"
    if [[ "$MODE" != "--dry-run" ]]; then
        echo "请确认要删除哪一个 (输入序号):"
        select choice in "${app_candidates[@]}"; do
            sudo rm -frv "$choice"
            echo "$(date) 删除应用: $choice" >> "$LOGFILE"
            break
        done
    else
        echo "[dry-run] 将删除以上候选应用"
        for c in "${app_candidates[@]}"; do
            echo "$(date) 预览删除应用: $c" >> "$LOGFILE"
        done
    fi
elif [ ${#app_candidates[@]} -eq 1 ]; then
    echo "发现应用: ${app_candidates[0]}"
    if [[ "$MODE" != "--dry-run" ]]; then
        sudo rm -frv "${app_candidates[0]}"
        echo "$(date) 删除应用: ${app_candidates[0]}" >> "$LOGFILE"
    else
        echo "[dry-run] 将删除: ${app_candidates[0]}"
        echo "$(date) 预览删除应用: ${app_candidates[0]}" >> "$LOGFILE"
    fi
else
    echo "未找到 ${APP_NAME}.app"
fi

# ---------------------------------------------------------
# 步骤 3: 清理用户个人资源库 (~/Library)
# ---------------------------------------------------------
echo -e "\n[步骤 3/7] 正在清理用户个人资源库 (~/Library)..."
safe_find_and_delete "$HOME/Library/Application Support" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Preferences" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Caches" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Logs" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/LaunchAgents" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Services" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/PreferencePanes" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/QuickLook" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Spotlight" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Saved Application State" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Containers" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Group Containers" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Application Scripts" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Internet Plug-Ins" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Screen Savers" "${APP_NAME}"
safe_find_and_delete "$HOME/Library/Widgets" "${APP_NAME}"

# ---------------------------------------------------------
# 步骤 4: 清理系统全局资源库 (/Library)
# ---------------------------------------------------------
echo -e "\n[步骤 4/7] 正在清理系统全局资源库 (/Library)..."
safe_find_and_delete "/Library/Application Support" "${APP_NAME}"
safe_find_and_delete "/Library/Preferences" "${APP_NAME}"
safe_find_and_delete "/Library/Caches" "${APP_NAME}"
safe_find_and_delete "/Library/LaunchAgents" "${APP_NAME}"
safe_find_and_delete "/Library/LaunchDaemons" "${APP_NAME}"
safe_find_and_delete "/Library/PreferencePanes" "${APP_NAME}"
safe_find_and_delete "/Library/QuickLook" "${APP_NAME}"
safe_find_and_delete "/Library/Spotlight" "${APP_NAME}"
safe_find_and_delete "/Library/Internet Plug-Ins" "${APP_NAME}"
safe_find_and_delete "/Library/Screen Savers" "${APP_NAME}"
safe_find_and_delete "/Library/Widgets" "${APP_NAME}"

# ---------------------------------------------------------
# 步骤 5: 清理系统级缓存目录
# /private/var/folders 是 macOS 的临时缓存目录
# ---------------------------------------------------------
echo -e "\n[步骤 5/7] 清理系统级缓存目录..."
safe_find_and_delete "/private/var/folders" "${APP_NAME}"

# ---------------------------------------------------------
# 步骤 6: 清理主目录下的隐藏配置文件
# 包括 ~/.config 和 ~/<.appname> 形式的隐藏目录
# ---------------------------------------------------------
echo -e "\n[步骤 6/7] 正在清理主目录下的隐藏配置文件..."
if [ -d "$HOME/.config" ]; then
    safe_find_and_delete "$HOME/.config" "${APP_NAME}"
fi
safe_find_and_delete "$HOME" ".${APP_NAME}"

# ---------------------------------------------------------
# 附加提示: 检查内核扩展目录
# /Library/Extensions 可能包含驱动类 kext
# 出于安全考虑，这里只提示，不自动删除
# ---------------------------------------------------------
echo -e "\n[提示] 检查内核扩展目录 (/Library/Extensions)..."
sudo find /Library/Extensions -iname "*${APP_NAME}*" -maxdepth 1 2>/dev/null

# ---------------------------------------------------------
# 步骤 7: 刷新 Launchpad / Dock 缓存 (解决图标残留问题)
# ---------------------------------------------------------
echo -e "\n[步骤 7/7] 正在刷新 Launchpad 图标缓存..."
if [[ "$MODE" != "--dry-run" ]]; then
    killall Dock
    echo "Dock 进程已重启，Launchpad/应用菜单应该已刷新。"
    echo "$(date) 刷新 Dock/Launchpad 缓存" >> "$LOGFILE"
else
    echo "[dry-run] 将重启 Dock 进程以刷新图标缓存。"
    echo "$(date) 预览刷新 Dock/Launchpad 缓存" >> "$LOGFILE"
fi

# 恢复 IFS
IFS=$IFS_BAK

echo -e "\n--- [${APP_NAME}] 卸载流程完成 ---"
echo "$(date) 卸载流程完成: [${APP_NAME}]" >> "$LOGFILE"
