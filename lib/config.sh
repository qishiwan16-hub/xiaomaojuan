xmj_init_config_state() {
  declare -ga XMJ_BOOT_MESSAGES=()
  declare -ga XMJ_BOOT_WARNINGS=()
  declare -ga XMJ_BOOT_ERRORS=()

  XMJ_CONFIG_READY=0
  XMJ_CONFIG_CREATED=0
  XMJ_BOOT_NOTICE_SHOWN=0
}

xmj_add_boot_message() {
  local message="${1:-}"

  if [ -n "$message" ]; then
    XMJ_BOOT_MESSAGES+=("$message")
  fi
}

xmj_add_boot_warning() {
  local message="${1:-}"

  if [ -n "$message" ]; then
    XMJ_BOOT_WARNINGS+=("$message")
  fi
}

xmj_add_boot_error() {
  local message="${1:-}"

  if [ -n "$message" ]; then
    XMJ_BOOT_ERRORS+=("$message")
  fi
}

xmj_detect_root_dir() {
  local base_dir="${XMJ_ROOT_DIR:-${SCRIPT_DIR:-}}"
  local source_path="${BASH_SOURCE[0]:-}"

  if [ -n "$base_dir" ] && [ -d "$base_dir" ]; then
    printf '%s' "$base_dir"
    return 0
  fi

  if [ -n "$source_path" ]; then
    printf '%s' "$(cd "$(dirname "$source_path")/.." && pwd)"
    return 0
  fi

  return 1
}

xmj_init_runtime_paths() {
  if ! XMJ_ROOT_DIR="$(xmj_detect_root_dir)"; then
    xmj_add_boot_error '无法定位脚本根目录，请确认你是在项目目录内运行 xiaomaojuan.sh。'
    return 1
  fi

  XMJ_LIB_DIR="$XMJ_ROOT_DIR/lib"
  XMJ_CONFIG_DIR="$XMJ_ROOT_DIR/config"
  XMJ_CONFIG_FILE="$XMJ_CONFIG_DIR/xiaomaojuan.conf"
  XMJ_DOCS_DIR="$XMJ_ROOT_DIR/docs"
  XMJ_CONFIG_GUIDE_FILE="$XMJ_DOCS_DIR/config-guide.md"
  XMJ_LOG_DIR="$XMJ_ROOT_DIR/logs"
}

xmj_expand_path() {
  local raw_path="${1:-}"

  case "$raw_path" in
    '~')
      printf '%s' "$HOME"
      ;;
    '~/'*)
      printf '%s/%s' "$HOME" "${raw_path#~/}"
      ;;
    *)
      printf '%s' "$raw_path"
      ;;
  esac
}

xmj_resolve_path() {
  local raw_path="${1:-}"
  local expanded_path

  expanded_path="$(xmj_expand_path "$raw_path")"

  if [ -z "$expanded_path" ]; then
    printf '%s' ''
    return 0
  fi

  case "$expanded_path" in
    /*)
      printf '%s' "$expanded_path"
      ;;
    *)
      printf '%s/%s' "$XMJ_ROOT_DIR" "$expanded_path"
      ;;
  esac
}

xmj_ensure_dir() {
  local dir_path="${1:-}"
  local dir_name="${2:-目录}"

  if [ -z "$dir_path" ]; then
    xmj_add_boot_error "${dir_name}路径为空，无法自动创建。"
    return 1
  fi

  if [ -d "$dir_path" ]; then
    return 0
  fi

  if mkdir -p "$dir_path" 2>/dev/null; then
    xmj_add_boot_message "已自动创建${dir_name}：$dir_path"
    return 0
  fi

  xmj_add_boot_error "无法创建${dir_name}：$dir_path"
  return 1
}

xmj_write_default_config() {
  if ! cat > "$XMJ_CONFIG_FILE" <<'EOF'
# 小猫卷配置文件
# 修改后重新运行 ./xiaomaojuan.sh 即可生效。
# 路径支持写成绝对路径，也支持使用 $HOME 或 ~/ 开头。

# 脚本显示名称，会出现在首页和标题区。
XMJ_SCRIPT_NAME="小猫卷"

# 作者名称，只用于展示。
XMJ_SCRIPT_AUTHOR="meoroll"

# 目标项目名称，只用于展示。
XMJ_TARGET_PROJECT="SillyTavern"

# SillyTavern 实际目录。
# 如果你装在别的位置，请改成自己的真实路径。
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"

# 备份目录。
# 可以写相对路径，例如 backups；相对路径会自动以脚本根目录为基准。
XMJ_BACKUP_DIR="backups"

# 日志目录。
# 启动 / 更新日志等详细输出会写到这里，避免直接刷满前台。
XMJ_LOG_DIR="logs"

# 主题模式。
# 可选值：pastel / moonlight
XMJ_THEME_MODE="pastel"

# 当前运行环境说明，会显示在首页信息区。
XMJ_RUNTIME_ENV="Termux / Android / Bash"

# 内置 Termux 字体预设名称。
XMJ_TERMUX_FONT_PRESET_NAME="霞鹜文楷等宽"

# 内置 Termux 字体预设下载地址。
XMJ_TERMUX_FONT_PRESET_URL="https://raw.githubusercontent.com/lxgw/LxgwWenKai/main/fonts/TTF/LXGWWenKaiMono-Regular.ttf"

# 内置 Termux 字体预设 MD5，用于校验下载结果。
XMJ_TERMUX_FONT_PRESET_MD5="612c16a3b40d91695635749c1493e02f"
EOF
  then
    xmj_add_boot_error "默认配置文件写入失败：$XMJ_CONFIG_FILE"
    return 1
  fi

  XMJ_CONFIG_CREATED=1
  xmj_add_boot_message "首次运行已生成默认配置：$XMJ_CONFIG_FILE"
  return 0
}

xmj_source_config_file() {
  local source_status=0

  set +u
  # shellcheck disable=SC1090
  source "$XMJ_CONFIG_FILE" 2>/dev/null || source_status=$?
  set -u

  if [ "$source_status" -ne 0 ]; then
    xmj_add_boot_error "配置文件读取失败，请检查语法：$XMJ_CONFIG_FILE"
    xmj_add_boot_error "可参考配置教程：$XMJ_CONFIG_GUIDE_FILE"
    return 1
  fi

  return 0
}

xmj_validate_required_text() {
  local var_name="${1:-}"
  local label="${2:-配置项}"
  local fallback="${3:-}"
  local current_value="${!var_name-}"
  local compact_value="${current_value//[[:space:]]/}"

  if [ -n "$compact_value" ]; then
    return 0
  fi

  printf -v "$var_name" '%s' "$fallback"
  xmj_add_boot_warning "${label}为空，已自动回退为默认值：$fallback"
}

xmj_apply_config_defaults() {
  : "${XMJ_SCRIPT_NAME:=小猫卷}"
  : "${XMJ_SCRIPT_AUTHOR:=meoroll}"
  : "${XMJ_TARGET_PROJECT:=SillyTavern}"
  : "${XMJ_SILLYTAVERN_PATH:=$HOME/SillyTavern}"
  : "${XMJ_BACKUP_DIR:=backups}"
  : "${XMJ_LOG_DIR:=logs}"
  : "${XMJ_THEME_MODE:=pastel}"
  : "${XMJ_RUNTIME_ENV:=Termux / Android / Bash}"
  : "${XMJ_TERMUX_FONT_PRESET_NAME:=霞鹜文楷等宽}"
  : "${XMJ_TERMUX_FONT_PRESET_URL:=https://raw.githubusercontent.com/lxgw/LxgwWenKai/main/fonts/TTF/LXGWWenKaiMono-Regular.ttf}"
  : "${XMJ_TERMUX_FONT_PRESET_MD5:=612c16a3b40d91695635749c1493e02f}"
}

xmj_validate_theme_mode() {
  case "${XMJ_THEME_MODE:-}" in
    pastel|moonlight)
      ;;
    '')
      XMJ_THEME_MODE='pastel'
      xmj_add_boot_warning '主题模式未设置，已自动改为 pastel。'
      ;;
    *)
      xmj_add_boot_warning "主题模式 ${XMJ_THEME_MODE} 无效，已自动改为 pastel（可选：pastel / moonlight）。"
      XMJ_THEME_MODE='pastel'
      ;;
  esac
}

xmj_config_status_text() {
  if [ "${#XMJ_BOOT_ERRORS[@]}" -gt 0 ]; then
    printf '%s' '启动失败'
  elif [ "${#XMJ_BOOT_WARNINGS[@]}" -gt 0 ]; then
    printf '%s' '配置已载入（含提示）'
  elif [ "${XMJ_CONFIG_CREATED:-0}" = '1' ]; then
    printf '%s' '首次初始化完成'
  else
    printf '%s' '配置已就绪'
  fi
}

xmj_validate_config() {
  xmj_validate_required_text 'XMJ_SCRIPT_NAME' '脚本名称' '小猫卷'
  xmj_validate_required_text 'XMJ_SCRIPT_AUTHOR' '作者' 'meoroll'
  xmj_validate_required_text 'XMJ_TARGET_PROJECT' '目标项目' 'SillyTavern'
  xmj_validate_required_text 'XMJ_SILLYTAVERN_PATH' 'SillyTavern 路径' "$HOME/SillyTavern"
  xmj_validate_required_text 'XMJ_BACKUP_DIR' '备份目录' 'backups'
  xmj_validate_required_text 'XMJ_LOG_DIR' '日志目录' 'logs'
  xmj_validate_required_text 'XMJ_RUNTIME_ENV' '运行环境说明' 'Termux / Android / Bash'
  xmj_validate_theme_mode

  XMJ_SILLYTAVERN_PATH="$(xmj_resolve_path "$XMJ_SILLYTAVERN_PATH")"
  XMJ_BACKUP_DIR="$(xmj_resolve_path "$XMJ_BACKUP_DIR")"
  XMJ_LOG_DIR="$(xmj_resolve_path "$XMJ_LOG_DIR")"

  if ! xmj_ensure_dir "$XMJ_BACKUP_DIR" '备份目录'; then
    return 1
  fi

  if ! xmj_ensure_dir "$XMJ_LOG_DIR" '日志目录'; then
    return 1
  fi

  if [ ! -d "$XMJ_SILLYTAVERN_PATH" ]; then
    xmj_add_boot_warning "未找到 SillyTavern 目录：$XMJ_SILLYTAVERN_PATH，可先进入面板，稍后再修改配置。"
  fi

  return 0
}

xmj_bootstrap_config() {
  xmj_init_config_state

  if ! xmj_init_runtime_paths; then
    return 1
  fi

  if ! xmj_ensure_dir "$XMJ_CONFIG_DIR" '配置目录'; then
    return 1
  fi

  if [ ! -f "$XMJ_CONFIG_FILE" ]; then
    if ! xmj_write_default_config; then
      return 1
    fi
  fi

  if ! xmj_source_config_file; then
    return 1
  fi

  xmj_apply_config_defaults

  if ! xmj_validate_config; then
    return 1
  fi

  XMJ_CONFIG_READY=1
  return 0
}
