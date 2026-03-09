xmj_init_font_state() {
  XMJ_FONT_ACTION_MESSAGE=''
  XMJ_FONT_ACTION_LEVEL='info'
}

xmj_font_set_notice() {
  XMJ_FONT_ACTION_LEVEL="${1:-info}"
  XMJ_FONT_ACTION_MESSAGE="${2:-}"
}

xmj_font_clear_notice() {
  XMJ_FONT_ACTION_MESSAGE=''
  XMJ_FONT_ACTION_LEVEL='info'
}

xmj_font_notice_color() {
  case "${XMJ_FONT_ACTION_LEVEL:-info}" in
    success)
      printf '%s' "$XMJ_CREAM"
      ;;
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_MIST"
      ;;
  esac
}

xmj_termux_font_dir() {
  printf '%s' "${HOME:-}/.termux"
}

xmj_termux_font_file() {
  printf '%s/font.ttf' "$(xmj_termux_font_dir)"
}

xmj_termux_font_backup_file() {
  printf '%s/font.ttf.bak' "$(xmj_termux_font_dir)"
}

xmj_termux_font_source_host() {
  printf '%s' 'ziti.net.cn'
}

xmj_file_md5() {
  local file_path="${1:-}"
  local md5_line

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  if command -v md5sum >/dev/null 2>&1; then
    md5_line="$(md5sum "$file_path" 2>/dev/null || true)"
    printf '%s' "${md5_line%% *}"
    return 0
  fi

  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$file_path" 2>/dev/null || true
    return 0
  fi

  return 1
}

xmj_termux_font_status_text() {
  local font_file
  local current_md5=''
  local preset_md5="${XMJ_TERMUX_FONT_PRESET_MD5:-}"

  font_file="$(xmj_termux_font_file)"
  if [ ! -f "$font_file" ]; then
    printf '%s' '默认字体'
    return 0
  fi

  current_md5="$(xmj_file_md5 "$font_file" || true)"
  if [ -n "$current_md5" ] && [ -n "$preset_md5" ] && [ "$current_md5" = "$preset_md5" ]; then
    printf '%s' "${XMJ_TERMUX_FONT_PRESET_NAME:-京华老宋体}（已应用）"
    return 0
  fi

  printf '%s' '已检测到自定义字体'
}

xmj_download_file() {
  local url="${1:-}"
  local output_path="${2:-}"

  if command -v curl >/dev/null 2>&1; then
    curl -fL --connect-timeout 15 --retry 2 --retry-delay 1 -o "$output_path" "$url"
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output_path" "$url"
    return $?
  fi

  return 127
}

xmj_reload_termux_settings() {
  if ! command -v termux-reload-settings >/dev/null 2>&1; then
    return 1
  fi

  termux-reload-settings >/dev/null 2>&1
}

xmj_install_termux_font_preset() {
  local font_name="${XMJ_TERMUX_FONT_PRESET_NAME:-京华老宋体}"
  local font_url="${XMJ_TERMUX_FONT_PRESET_URL:-}"
  local expected_md5="${XMJ_TERMUX_FONT_PRESET_MD5:-}"
  local font_dir
  local font_file
  local backup_file
  local tmp_file
  local actual_md5=''
  local download_status=0

  if [ -z "${HOME:-}" ]; then
    xmj_font_set_notice 'warn' 'HOME 未设置，无法写入 Termux 字体目录。'
    return 1
  fi

  if [ -z "$font_url" ]; then
    xmj_font_set_notice 'warn' '未配置内置字体下载地址。'
    return 1
  fi

  font_dir="$(xmj_termux_font_dir)"
  font_file="$(xmj_termux_font_file)"
  backup_file="$(xmj_termux_font_backup_file)"
  tmp_file="${font_file}.tmp"

  if ! mkdir -p "$font_dir" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法创建字体目录：$font_dir"
    return 1
  fi

  rm -f "$tmp_file"
  if xmj_download_file "$font_url" "$tmp_file"; then
    :
  else
    download_status=$?
    rm -f "$tmp_file"
    if [ "$download_status" -eq 127 ]; then
      xmj_font_set_notice 'warn' '系统缺少 curl 或 wget，无法下载字体。'
    else
      xmj_font_set_notice 'warn' "字体下载失败：$font_name"
    fi
    return 1
  fi

  if [ ! -s "$tmp_file" ]; then
    rm -f "$tmp_file"
    xmj_font_set_notice 'warn' '下载结果为空，已取消应用字体。'
    return 1
  fi

  if [ -n "$expected_md5" ]; then
    actual_md5="$(xmj_file_md5 "$tmp_file" || true)"
    if [ -z "$actual_md5" ]; then
      rm -f "$tmp_file"
      xmj_font_set_notice 'warn' '系统缺少 MD5 校验能力，已取消应用字体。'
      return 1
    fi

    if [ "$actual_md5" != "$expected_md5" ]; then
      rm -f "$tmp_file"
      xmj_font_set_notice 'warn' '字体校验失败，已取消应用。'
      return 1
    fi
  fi

  if [ -f "$font_file" ]; then
    cp "$font_file" "$backup_file" 2>/dev/null || true
  fi

  if ! mv "$tmp_file" "$font_file" 2>/dev/null; then
    rm -f "$tmp_file"
    xmj_font_set_notice 'warn' "无法写入字体文件：$font_file"
    return 1
  fi

  if xmj_reload_termux_settings; then
    xmj_font_set_notice 'success' "已应用 ${font_name}，若未立即生效请重开 Termux。"
  else
    xmj_font_set_notice 'success' "已写入 ${font_name}，请手动执行 termux-reload-settings 或重开 Termux。"
  fi

  return 0
}

xmj_restore_termux_default_font() {
  local font_file

  font_file="$(xmj_termux_font_file)"
  if [ ! -f "$font_file" ]; then
    xmj_font_set_notice 'info' '当前已经是默认字体。'
    return 0
  fi

  if ! rm -f "$font_file" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法删除字体文件：$font_file"
    return 1
  fi

  if xmj_reload_termux_settings; then
    xmj_font_set_notice 'success' '已恢复 Termux 默认字体。'
  else
    xmj_font_set_notice 'success' '已删除自定义字体，请手动执行 termux-reload-settings 或重开 Termux。'
  fi

  return 0
}

xmj_manual_reload_termux_settings() {
  if xmj_reload_termux_settings; then
    xmj_font_set_notice 'success' '已执行 termux-reload-settings。'
    return 0
  fi

  xmj_font_set_notice 'warn' '未找到 termux-reload-settings，请重开 Termux。'
  return 1
}
