xmj_section_phrase() {
  local section="${1:-}"

  case "$section" in
    info) printf '%s' 'public memo' ;;
    update) printf '%s' 'update ribbon' ;;
    backup) printf '%s' 'backup lane' ;;
    dependency) printf '%s' 'env notice' ;;
    extend) printf '%s' 'script bloom' ;;
    setting) printf '%s' 'setting room' ;;
    about) printf '%s' 'about neko' ;;
    *) printf '%s' 'preview page' ;;
  esac
}

xmj_render_header() {
  local script_name="${XMJ_SCRIPT_NAME:-小猫卷}"
  local author="${XMJ_SCRIPT_AUTHOR:-meoroll}"

  printf '\n'
  printf '%b%s%b\n' "$XMJ_PINK_SOFT" "  し ~｡ ｡~ っ  ${script_name}  し ~｡ ｡~ っ" "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_WHITE" '  little panel memory' "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_MIST" "  ${author} の preview page" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '═' 68
}

xmj_render_info_block() {
  local key

  xmj_render_section_title 'info'
  for key in "${XMJ_INFO_ORDER[@]}"; do
    printf '  %b%s%b｜%b%s%b\n' "$XMJ_BLUE_SOFT" "$key" "$XMJ_RESET" "$XMJ_WHITE" "${XMJ_INFO_VALUE[$key]}" "$XMJ_RESET"
  done
  printf '\n'
}

xmj_render_fact_line() {
  local label="${1:-}"
  local value="${2:-}"

  printf '  %b%s%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$label" "$XMJ_RESET" "$XMJ_WHITE" "$value" "$XMJ_RESET"
}

xmj_render_path_block() {
  local label="${1:-}"
  local path_value="${2:-}"
  local state_value="${3:-}"

  printf '  %b%s%b\n' "$XMJ_BLUE_SOFT" "$label" "$XMJ_RESET"
  printf '    %b路径%b：%b%s%b\n' "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$path_value" "$XMJ_RESET"
  printf '    %b状态%b：%b%s%b\n' "$XMJ_MIST" "$XMJ_RESET" "$XMJ_CREAM" "$state_value" "$XMJ_RESET"
}

xmj_render_section_title() {
  local section="${1:-}"
  local decor="${XMJ_SECTION_DECOR[$section]}"
  local title="${XMJ_SECTION_TITLE[$section]}"
  local phrase

  phrase="$(xmj_section_phrase "$section")"
  printf '%b%s%b %b%s%b %b--%b %b%s%b %b× . *%b\n' "$XMJ_PINK" "$decor" "$XMJ_RESET" "$XMJ_BLUE_SOFT" "$phrase" "$XMJ_RESET" "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$title" "$XMJ_RESET" "$XMJ_LAVENDER" "$XMJ_RESET"
}

xmj_render_menu_item() {
  local id="${1:-}"
  printf '%bʚ✞%s✞ɞ%b｜%b%s%b' "$XMJ_PINK" "$id" "$XMJ_RESET" "$XMJ_WHITE" "${XMJ_MENU_LABEL[$id]}" "$XMJ_RESET"
}

xmj_render_menu_row() {
  local left_id="${1:-}"
  local right_id="${2:-}"

  printf '  '
  xmj_render_menu_item "$left_id"

  if [ -n "$right_id" ]; then
    printf '      '
    xmj_render_menu_item "$right_id"
  fi

  printf '\n'
}

xmj_render_menu_block() {
  local section="${1:-}"
  local ids=()
  local id
  local i

  xmj_render_section_title "$section"

  for id in "${XMJ_MENU_IDS[@]}"; do
    if [ "${XMJ_MENU_SECTION[$id]}" = "$section" ]; then
      ids+=("$id")
    fi
  done

  for ((i = 0; i < ${#ids[@]}; i += 2)); do
    xmj_render_menu_row "${ids[$i]}" "${ids[$((i + 1))]:-}"
  done

  printf '\n'
}

xmj_render_input_hint() {
  printf '%b%s%b\n' "$XMJ_BLUE" '  请输入编号跳转页面，输入 00 可退出面板。' "$XMJ_RESET"
}

xmj_render_home() {
  local section

  xmj_clear_screen
  xmj_render_header
  printf '\n'

  for section in "${XMJ_SECTION_ORDER[@]}"; do
    if [ "$section" = 'info' ]; then
      continue
    fi
    xmj_render_menu_block "$section"
  done

  xmj_render_input_hint
}

xmj_render_boot_lines() {
  local color="${1:-$XMJ_WHITE}"
  shift || true
  local line

  for line in "$@"; do
    printf '  %b• %s%b\n' "$color" "$line" "$XMJ_RESET"
  done
}

xmj_render_startup_notice() {
  if [ "${XMJ_BOOT_NOTICE_SHOWN:-0}" = '1' ]; then
    return 0
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'info'
  printf '\n'
  printf '  %b启动配置已完成，以下是本次启动摘要。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b配置文件%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "${XMJ_CONFIG_FILE:-未生成}" "$XMJ_RESET"
  printf '  %b脚本根目录%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "${XMJ_ROOT_DIR:-未识别}" "$XMJ_RESET"
  printf '\n'

  if [ "${#XMJ_BOOT_MESSAGES[@]}" -gt 0 ]; then
    printf '  %b初始化信息%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
    xmj_render_boot_lines "$XMJ_WHITE" "${XMJ_BOOT_MESSAGES[@]}"
    printf '\n'
  fi

  if [ "${#XMJ_BOOT_WARNINGS[@]}" -gt 0 ]; then
    printf '  %b温和提示%b\n' "$XMJ_WARN" "$XMJ_RESET"
    xmj_render_boot_lines "$XMJ_CREAM" "${XMJ_BOOT_WARNINGS[@]}"
    printf '\n'
  fi

  if [ "${#XMJ_BOOT_MESSAGES[@]}" -eq 0 ] && [ "${#XMJ_BOOT_WARNINGS[@]}" -eq 0 ]; then
    printf '  %b本次启动未发现额外提示，配置状态正常。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
  fi

  printf '  %b说明%b：%b当前业务菜单仍然是占位页，不会执行更新、备份、安装等真实操作。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  XMJ_BOOT_NOTICE_SHOWN=1
  xmj_wait_for_enter '按回车进入首页'
}

xmj_render_startup_failure() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'info'
  printf '\n'
  printf '  %b启动配置失败，面板未继续加载。%b\n' "$XMJ_WARN" "$XMJ_RESET"
  printf '  %b请优先检查以下项目：%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"

  if [ "${#XMJ_BOOT_ERRORS[@]}" -gt 0 ]; then
    xmj_render_boot_lines "$XMJ_WARN" "${XMJ_BOOT_ERRORS[@]}"
  else
    printf '  %b• 未提供具体错误信息，请检查脚本权限与配置文件语法。%b\n' "$XMJ_WARN" "$XMJ_RESET"
  fi

  if [ -n "${XMJ_CONFIG_FILE:-}" ]; then
    printf '\n'
    printf '  %b配置文件%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$XMJ_CONFIG_FILE" "$XMJ_RESET"
  fi

  if [ -n "${XMJ_CONFIG_GUIDE_FILE:-}" ]; then
    printf '  %b配置教程%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$XMJ_CONFIG_GUIDE_FILE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b面板会在此停止，不会直接崩溃退出到异常堆栈。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车结束脚本'
}

xmj_render_about_status_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'about'
  printf '\n'
  xmj_render_fact_line '当前编号' '21'
  xmj_render_fact_line '当前页面' "${XMJ_MENU_LABEL['21']}"
  printf '\n'
  xmj_render_fact_line '状态' "$(xmj_config_status_text)"
  xmj_render_fact_line '主题' "$(xmj_theme_label)"
  xmj_render_fact_line '配置文件' "${XMJ_CONFIG_FILE:-未生成}"
  xmj_render_fact_line '脚本根目录' "${XMJ_ROOT_DIR:-未识别}"
  printf '\n'
  xmj_render_path_block 'SillyTavern' \
    "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")" \
    "$(xmj_dir_state "${XMJ_SILLYTAVERN_PATH:-}" '已发现' '待确认')"
  printf '\n'
  xmj_render_path_block '备份目录' \
    "$(xmj_display_path "${XMJ_BACKUP_DIR:-}")" \
    "$(xmj_dir_state "${XMJ_BACKUP_DIR:-}" '已就绪' '待创建')"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车返回首页'
}

xmj_render_about_panel_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'about'
  printf '\n'
  xmj_render_fact_line '当前编号' '22'
  xmj_render_fact_line '当前页面' "${XMJ_MENU_LABEL['22']}"
  printf '\n'
  printf '  %b小猫卷是一个运行在 Termux 里的 Bash 面板预览框架。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b首页原先的信息公开已收纳到关于页，首页只保留功能分组。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '名称' "${XMJ_SCRIPT_NAME:-小猫卷}"
  xmj_render_fact_line '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}"
  xmj_render_fact_line '目标' "${XMJ_TARGET_PROJECT:-SillyTavern}"
  xmj_render_fact_line '环境' "${XMJ_RUNTIME_ENV:-Termux / Android / Bash}"
  xmj_render_fact_line '主题' "$(xmj_theme_label)"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车返回首页'
}

xmj_render_author_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'about'
  printf '\n'
  xmj_render_fact_line '当前编号' '23'
  xmj_render_fact_line '当前页面' "${XMJ_MENU_LABEL['23']}"
  printf '\n'
  xmj_render_fact_line '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}"
  xmj_render_fact_line '标题副文' 'little panel memory'
  xmj_render_fact_line '页面定位' 'preview page'
  printf '\n'
  printf '  %b当前版本主要用于确认配置、面板结构和占位跳转。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b不会执行更新、备份、安装或 Git 回滚等真实业务操作。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车返回首页'
}

xmj_render_menu_page() {
  local id="${1:-}"

  case "$id" in
    21)
      xmj_render_about_status_page
      ;;
    22)
      xmj_render_about_panel_page
      ;;
    23)
      xmj_render_author_page
      ;;
    *)
      xmj_render_placeholder_page "$id"
      ;;
  esac
}

xmj_render_placeholder_page() {
  local id="${1:-}"
  local section="${XMJ_MENU_SECTION[$id]}"
  local title="${XMJ_MENU_LABEL[$id]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title "$section"
  printf '\n'
  printf '  %b当前编号%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_PINK" "$id" "$XMJ_RESET"
  printf '  %b当前页面%b：%b%s%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$title" "$XMJ_RESET"
  printf '\n'
  printf '  %b当前功能已预留，暂未实现。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b这里只展示小猫卷的面板框架与占位跳转。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
  printf '  %b不会执行更新、备份、依赖安装、Git 操作等任何真实逻辑。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车返回首页'
}

xmj_render_invalid_input() {
  local input="${1:-}"

  printf '\n'
  printf '  %b输入无效%b：%b%s%b\n' "$XMJ_WARN" "$XMJ_RESET" "$XMJ_PINK" "$input" "$XMJ_RESET"
  printf '  %b仅支持输入 00 - 23 的菜单编号。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  xmj_wait_for_enter '按回车返回首页'
}
