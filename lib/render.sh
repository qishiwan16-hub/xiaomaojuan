xmj_section_phrase() {
  local section="${1:-}"

  case "$section" in
    info) printf '%s' 'honey entrance' ;;
    update) printf '%s' 'update atelier' ;;
    backup) printf '%s' 'memory archive' ;;
    dependency) printf '%s' 'runtime garden' ;;
    extend) printf '%s' 'extension room' ;;
    setting) printf '%s' 'soft settings' ;;
    about) printf '%s' 'little about' ;;
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

xmj_render_setting_card() {
  local title="${1:-}"
  local description="${2:-}"
  local status_text="${3:-}"

  printf '  %b♡ %s%b\n' "$XMJ_PINK" "$title" "$XMJ_RESET"

  if [ -n "$description" ]; then
    printf '    %b%s%b\n' "$XMJ_WHITE" "$description" "$XMJ_RESET"
  fi

  if [ -n "$status_text" ]; then
    printf '    %b%s%b\n' "$XMJ_MIST" "$status_text" "$XMJ_RESET"
  fi
}

xmj_render_notice_line() {
  local notice_color=''

  if [ -z "${XMJ_FONT_ACTION_MESSAGE:-}" ]; then
    return 0
  fi

  notice_color="$(xmj_font_notice_color)"
  printf '\n'
  printf '  %b%s%b\n' "$notice_color" "$XMJ_FONT_ACTION_MESSAGE" "$XMJ_RESET"
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

xmj_render_setting_home_block() {
  xmj_render_section_title 'setting'
  xmj_render_page_intro \
    '首页设置区现在只保留一个收纳入口，详细项已经放进设置中心。' \
    '基础设置、主题外观、字体管理和高级预留都会在里面分开展示。'
  printf '\n'
  xmj_render_fact_line '当前摘要' "$(xmj_theme_label) · $(xmj_termux_font_status_text)"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  printf '\n'
  xmj_render_action_item '17' "${XMJ_MENU_LABEL['17']}"
  printf '  %b· 已收纳%b：%b基础设置 / 主题外观 / 字体管理 / 高级项预留%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
}

xmj_render_menu_block() {
  local section="${1:-}"
  local ids=()
  local id
  local i

  if [ "$section" = 'setting' ]; then
    xmj_render_setting_home_block
    return 0
  fi

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
  local hint='  请输入编号，17 可进入设置中心，00 退出。'

  panel_width="$(xmj_panel_width)"
  if [ "$panel_width" -lt 30 ]; then
    hint='  编号 / 17设置 / 00退出'
  elif [ "$panel_width" -lt 42 ]; then
    hint='  输入编号，17 设置，00 退出。'
  fi

  printf '%b%s%b\n' "$XMJ_BLUE" "$hint" "$XMJ_RESET"
}

xmj_render_home() {
  local section

  xmj_clear_screen
  xmj_render_header
  printf '\n'
  xmj_render_info_block

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

xmj_setting_view_title() {
  local view="${1:-home}"

  case "$view" in
    basic)
      printf '%s' '基础设置'
      ;;
    theme)
      printf '%s' '主题 / 外观'
      ;;
    font)
      printf '%s' '字体管理'
      ;;
    advanced)
      printf '%s' '高级项预留'
      ;;
    *)
      printf '%s' '设置中心'
      ;;
  esac
}

xmj_setting_view_id() {
  local view="${1:-home}"

  case "$view" in
    basic)
      printf '%s' '20'
      ;;
    theme)
      printf '%s' '18'
      ;;
    font)
      printf '%s' '19'
      ;;
    advanced)
      printf '%s' '17-4'
      ;;
    *)
      printf '%s' '17'
      ;;
  esac
}

xmj_render_setting_overview_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity "$(xmj_setting_view_id 'home')" "$(xmj_setting_view_title 'home')"
  printf '\n'
  xmj_render_page_intro \
    '设置相关内容已经收纳到这个内部页，不再把路径、主题和字体细项铺在首页外层。' \
    '你可以从这里进入基础设置、主题外观、字体管理和高级项预留。'
  printf '\n'
  xmj_render_fact_line '当前主题' "$(xmj_theme_label)"
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '配置状态' "$(xmj_config_status_text)"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  printf '\n'
  xmj_render_setting_card \
    '1 · 基础设置' \
    '集中看脚本名称、运行环境、SillyTavern 路径和备份目录。' \
    "当前：$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}") / $(xmj_display_path "${XMJ_BACKUP_DIR:-}")"
  printf '\n'
  xmj_render_setting_card \
    '2 · 主题 / 外观' \
    '延续粉蓝白浅色系与可爱卡片风，顶部主标题样式保持当前版本。' \
    "当前：$(xmj_theme_label)"
  printf '\n'
  xmj_render_setting_card \
    '3 · 字体管理' \
    '内置字体安装、恢复默认字体、重新加载 Termux 设置都集中在这里。' \
    "当前：$(xmj_termux_font_status_text)"
  printf '\n'
  xmj_render_setting_card \
    '4 · 高级项预留' \
    '先把结构和收纳位留好，本次不会顺手接入更新、回退、备份、依赖安装等无关业务。' \
    '当前：占位说明页'
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '进入基础设置'
  xmj_render_action_item '2' '进入主题 / 外观'
  xmj_render_action_item '3' '进入字体管理'
  xmj_render_action_item '4' '查看高级项预留'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 0。'
}

xmj_render_setting_basic_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity "$(xmj_setting_view_id 'basic')" "$(xmj_setting_view_title 'basic')"
  printf '\n'
  xmj_render_page_intro \
    '这里集中展示当前脚本的基础配置，不再把路径细项散放在首页外层。' \
    '当前版本只做展示和状态确认，不会在这里直接改写配置文件。'
  printf '\n'
  xmj_render_fact_line '脚本名称' "${XMJ_SCRIPT_NAME:-小猫卷}"
  xmj_render_fact_line '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}"
  xmj_render_fact_line '目标项目' "${XMJ_TARGET_PROJECT:-SillyTavern}"
  xmj_render_fact_line '运行环境' "${XMJ_RUNTIME_ENV:-Termux / Android / Bash}"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  printf '\n'
  xmj_render_path_block 'SillyTavern 路径' \
    "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")" \
    "$(xmj_dir_state "${XMJ_SILLYTAVERN_PATH:-}" '已发现' '待确认')"
  printf '\n'
  xmj_render_path_block '备份目录' \
    "$(xmj_display_path "${XMJ_BACKUP_DIR:-}")" \
    "$(xmj_dir_state "${XMJ_BACKUP_DIR:-}" '已就绪' '待创建')"
  printf '\n'
  xmj_render_page_intro \
    '如果你要改这些值，请直接编辑 config/xiaomaojuan.conf。' \
    '这里的目的是让你在面板里先确认配置有没有读对。'
  xmj_render_notice_line
  xmj_render_action_footer '输入 0 返回设置中心。'
}

xmj_render_setting_theme_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity "$(xmj_setting_view_id 'theme')" "$(xmj_setting_view_title 'theme')"
  printf '\n'
  xmj_render_page_intro \
    '主题 / 外观页主要负责展示当前视觉方案，不在这里直接改动顶部主标题样式。' \
    '既定方向仍然是粉蓝白浅色系、可爱展示卡风格，只保留同系列柔和分支。'
  printf '\n'
  xmj_render_fact_line '当前主题' "$(xmj_theme_label)"
  xmj_render_fact_line '主题字段' "${XMJ_THEME_MODE:-pastel}"
  xmj_render_fact_line '边框风格' '软糖感分隔线 / 浅色渐柔边框'
  xmj_render_fact_line '标题状态' '保持当前主标题装饰，不额外重做'
  printf '\n'
  xmj_render_setting_card \
    'pastel · 粉蓝白系' \
    '更贴合当前首页与设置中心的默认外观，适合保留轻柔可爱感。' \
    '推荐：默认主题'
  printf '\n'
  xmj_render_setting_card \
    'moonlight · 月光蓝紫系' \
    '在同一套卡片结构里换成更偏蓝紫的柔和配色。' \
    '可通过配置项 XMJ_THEME_MODE 手动切换'
  printf '\n'
  xmj_render_page_intro \
    '如果你要切换主题，请编辑 config/xiaomaojuan.conf 里的 XMJ_THEME_MODE。' \
    '这里暂时只做展示，不额外加入热切换逻辑。'
  xmj_render_notice_line
  xmj_render_action_footer '输入 0 返回设置中心。'
}

xmj_render_setting_font_page() {
  local font_file
  local backup_file
  local backup_state='未生成'
  local preset_format='未知'

  font_file="$(xmj_termux_font_file)"
  backup_file="$(xmj_termux_font_backup_file)"
  if [ -f "$backup_file" ]; then
    backup_state='已存在'
  fi

  case "$(xmj_termux_font_extension "${XMJ_TERMUX_FONT_PRESET_URL:-}")" in
    ttf)
      preset_format='TTF'
      ;;
    otf)
      preset_format='OTF'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity "$(xmj_setting_view_id 'font')" "$(xmj_setting_view_title 'font')"
  printf '\n'
  xmj_render_page_intro \
    '字体管理现在独立收纳在设置中心内部，所有真实可执行动作都集中在这里。' \
    '安装会写入整个 Termux 的字体文件，不只是改小猫卷当前页面。'
  printf '\n'
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '字体路径' "$(xmj_display_path "$font_file")"
  xmj_render_fact_line '备份状态' "$backup_state"
  xmj_render_fact_line '内置预设' "${XMJ_TERMUX_FONT_PRESET_NAME:-未设置}"
  xmj_render_fact_line '下载来源' "$(xmj_termux_font_source_host)"
  xmj_render_fact_line '资源格式' "$preset_format"
  printf '\n'
  xmj_render_setting_card \
    '安装策略' \
    '会先创建 ~/.termux 目录，再下载字体到临时文件，校验成功后写入 font.ttf。' \
    '失败时不会把错误页面或空文件写成字体'
  printf '\n'
  xmj_render_setting_card \
    '恢复策略' \
    '删除当前自定义字体后尝试重新加载 Termux 设置。' \
    '若没有 termux-reload-settings，会提示你手动重开 Termux'
  printf '\n'
  xmj_render_page_intro \
    '如果你后面要自定义别的字体，只需要改配置里的预设名称、直链和 MD5。' \
    '当前内置字体优先使用真实可访问的中文资源，避免旧直链失效导致无法下载。'
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' "安装内置字体：${XMJ_TERMUX_FONT_PRESET_NAME:-未设置}"
  xmj_render_action_item '2' '恢复默认字体'
  xmj_render_action_item '3' '重新加载 Termux 设置'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入 1 / 2 / 3 / 0。'
}

xmj_render_setting_advanced_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity "$(xmj_setting_view_id 'advanced')" "$(xmj_setting_view_title 'advanced')"
  printf '\n'
  xmj_render_page_intro \
    '这里先保留高级项的结构位置，避免以后又把细项重新摊回首页。' \
    '本次仍然严格限定范围，不在这里接入更新、回退、备份、依赖安装等无关业务。'
  printf '\n'
  xmj_render_fact_line '功能状态' '占位中'
  xmj_render_fact_line '当前定位' '只保留结构，不执行真实业务动作'
  xmj_render_fact_line '收纳原则' '设置相关内容统一留在设置中心内部'
  printf '\n'
  xmj_render_setting_card \
    '后续可放入的内容' \
    '例如更细的显示偏好、实验项开关、额外字体策略说明。' \
    '当前：仍为说明页'
  xmj_render_notice_line
  xmj_render_action_footer '输入 0 返回设置中心。'
}

xmj_render_setting_center_page() {
  local view="${1:-home}"

  case "$view" in
    basic)
      xmj_render_setting_basic_page
      ;;
    theme)
      xmj_render_setting_theme_page
      ;;
    font)
      xmj_render_setting_font_page
      ;;
    advanced)
      xmj_render_setting_advanced_page
      ;;
    *)
      xmj_render_setting_overview_page
      ;;
  esac
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
    '首页现在只保留功能分组，设置细项已经收纳到设置中心里。'
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
