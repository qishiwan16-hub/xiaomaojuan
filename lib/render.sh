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
  local panel_width
  local title_line=""
  local subtitle_line='  little panel memory'
  local author_line="  ${author} の preview page"

  panel_width="$(xmj_panel_width)"
  if [ "${#script_name}" -gt $((panel_width - 8)) ]; then
    title_line="  ${script_name}"
  elif [ "$panel_width" -lt 34 ]; then
    title_line="  し ｡･ω･｡ ${script_name}"
    subtitle_line='  panel memory'
    author_line="  ${author}"
  elif [ "$panel_width" -lt 46 ]; then
    title_line="  し ｡･ω･｡ ${script_name} っ"
    subtitle_line='  little memory'
    author_line="  ${author} preview"
  elif [ "$panel_width" -lt 58 ]; then
    title_line="  し ｡･ω･｡ ${script_name} ｡･ω･｡ っ"
    author_line="  ${author} の preview"
  else
    title_line="  し ~｡ ｡~ っ  ${script_name}  し ~｡ ｡~ っ"
  fi

  printf '\n'
  printf '%b%s%b\n' "$XMJ_PINK_SOFT" "$title_line" "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_WHITE" "$subtitle_line" "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_MIST" "$author_line" "$XMJ_RESET"
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

xmj_render_page_identity() {
  local id="${1:-}"
  local title="${2:-}"

  xmj_render_fact_line '当前编号' "$id"
  xmj_render_fact_line '当前页面' "$title"
}

xmj_render_page_intro() {
  local primary_text="${1:-}"
  local secondary_text="${2:-}"

  if [ -n "$primary_text" ]; then
    printf '  %b%s%b\n' "$XMJ_WHITE" "$primary_text" "$XMJ_RESET"
  fi

  if [ -n "$secondary_text" ]; then
    printf '  %b%s%b\n' "$XMJ_MIST" "$secondary_text" "$XMJ_RESET"
  fi
}

xmj_render_action_item() {
  local key="${1:-}"
  local label="${2:-}"

  printf '  %b[%s]%b｜%b%s%b\n' "$XMJ_PINK" "$key" "$XMJ_RESET" "$XMJ_WHITE" "$label" "$XMJ_RESET"
}

xmj_render_page_footer() {
  local prompt="${1:-按回车返回首页}"

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter "$prompt"
}

xmj_render_action_footer() {
  local hint="${1:-输入编号继续。}"

  printf '\n'
  printf '  %b%s%b\n' "$XMJ_BLUE_SOFT" "$hint" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
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
  local panel_width
  local hint='  请输入编号，00 退出。'

  panel_width="$(xmj_panel_width)"
  if [ "$panel_width" -lt 30 ]; then
    hint='  编号 / 00退出'
  elif [ "$panel_width" -lt 42 ]; then
    hint='  输入编号，00 退出。'
  fi

  printf '%b%s%b\n' "$XMJ_BLUE" "$hint" "$XMJ_RESET"
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
  xmj_render_page_identity '21' "${XMJ_MENU_LABEL['21']}"
  printf '\n'
  xmj_render_page_intro \
    '这里收纳当前脚本的运行状态和关键目录。' \
    '比首页更完整，方便你确认配置有没有落到正确位置。'
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
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_script_setting_page() {
  local font_file
  local backup_file
  local notice_color=''
  local backup_state='未生成'

  font_file="$(xmj_termux_font_file)"
  backup_file="$(xmj_termux_font_backup_file)"
  if [ -f "$backup_file" ]; then
    backup_state='已存在'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity '18' "${XMJ_MENU_LABEL['18']}"
  printf '\n'
  xmj_render_page_intro \
    '这里处理脚本外观和 Termux 字体相关设置。' \
    '字体修改会作用于整个 Termux，而不是只改小猫卷这一页。'
  printf '\n'
  xmj_render_fact_line '主题风格' "$(xmj_theme_label)"
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '字体路径' "$(xmj_display_path "$font_file")"
  xmj_render_fact_line '备份状态' "$backup_state"
  xmj_render_fact_line '内置预设' "${XMJ_TERMUX_FONT_PRESET_NAME:-京华老宋体}"
  xmj_render_fact_line '下载来源' "$(xmj_termux_font_source_host)"
  printf '\n'
  xmj_render_page_intro \
    '京华老宋体不是等宽字体，用在终端里菜单可能会有轻微错位。' \
    '如果你后面换别的字体，只要改配置里的预设名称、直链和 MD5 就行。'
  printf '\n'
  xmj_render_action_item '1' "安装内置字体：${XMJ_TERMUX_FONT_PRESET_NAME:-京华老宋体}"
  xmj_render_action_item '2' '恢复默认字体'
  xmj_render_action_item '3' '重新加载 Termux 设置'
  xmj_render_action_item '0' '返回首页'

  if [ -n "${XMJ_FONT_ACTION_MESSAGE:-}" ]; then
    notice_color="$(xmj_font_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_FONT_ACTION_MESSAGE" "$XMJ_RESET"
  fi

  xmj_render_action_footer '输入 1 / 2 / 3 / 0。'
}

xmj_render_about_panel_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'about'
  printf '\n'
  xmj_render_page_identity '22' "${XMJ_MENU_LABEL['22']}"
  printf '\n'
  xmj_render_page_intro \
    '小猫卷目前是一个运行在 Termux 里的 Bash 面板预览框架。' \
    '首页现在只保留功能分组，详细说明收纳在关于页。'
  printf '\n'
  xmj_render_fact_line '名称' "${XMJ_SCRIPT_NAME:-小猫卷}"
  xmj_render_fact_line '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}"
  xmj_render_fact_line '目标' "${XMJ_TARGET_PROJECT:-SillyTavern}"
  xmj_render_fact_line '环境' "${XMJ_RUNTIME_ENV:-Termux / Android / Bash}"
  xmj_render_fact_line '主题' "$(xmj_theme_label)"
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_author_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'about'
  printf '\n'
  xmj_render_page_identity '23' "${XMJ_MENU_LABEL['23']}"
  printf '\n'
  xmj_render_page_intro \
    '这里保留作者和这套预览页面的视觉备注。' \
    '主要还是方便你确认现在看到的是哪一版面板风格。'
  printf '\n'
  xmj_render_fact_line '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}"
  xmj_render_fact_line '标题副文' 'little panel memory'
  xmj_render_fact_line '页面定位' 'preview page'
  printf '\n'
  xmj_render_page_intro \
    '当前版本主要用于确认配置、面板结构和占位跳转。' \
    '不会执行更新、备份、安装或 Git 回滚等真实业务操作。'
  xmj_render_page_footer '按回车返回首页'
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
  xmj_render_page_identity "$id" "$title"
  printf '\n'
  xmj_render_page_intro \
    '这一页的入口已经留好，但真实功能还没接上。' \
    '当前版本只展示面板骨架与跳转结构，不会执行任何真实操作。'
  printf '\n'
  xmj_render_fact_line '所属分组' "${XMJ_SECTION_TITLE[$section]}"
  xmj_render_fact_line '功能状态' '预留中'
  printf '\n'
  xmj_render_page_intro \
    '你现在看到的是视觉占位页，后续会在这里补上对应业务逻辑。' \
    '更新、备份、安装依赖、Git 操作等都还没有真正接入。'
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_invalid_input() {
  local input="${1:-}"

  printf '\n'
  printf '  %b输入无效%b：%b%s%b\n' "$XMJ_WARN" "$XMJ_RESET" "$XMJ_PINK" "$input" "$XMJ_RESET"
  printf '  %b仅支持输入 00 - 23 的菜单编号。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  xmj_wait_for_enter '按回车返回首页'
}
