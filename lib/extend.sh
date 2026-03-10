xmj_extend_scripts_dir() {
  printf '%s' "${XMJ_ROOT_DIR:-.}/scripts"
}

xmj_extend_reserved_slot_path() {
  printf '%s' "$(xmj_extend_scripts_dir)/reserved-slot.sh"
}

xmj_extend_relative_path() {
  local file_path="${1:-}"

  case "$file_path" in
    "${XMJ_ROOT_DIR:-}/"*)
      printf '%s' "${file_path#"${XMJ_ROOT_DIR}/"}"
      ;;
    *)
      printf '%s' "$file_path"
      ;;
  esac
}

xmj_extend_clear_notice() {
  XMJ_EXTEND_NOTICE_LEVEL=''
  XMJ_EXTEND_NOTICE_MESSAGE=''
}

xmj_extend_set_notice() {
  XMJ_EXTEND_NOTICE_LEVEL="${1:-info}"
  XMJ_EXTEND_NOTICE_MESSAGE="${2:-}"
}

xmj_extend_notice_color() {
  case "${XMJ_EXTEND_NOTICE_LEVEL:-info}" in
    success)
      printf '%s' "$XMJ_CREAM"
      ;;
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_render_extend_notice() {
  local notice_color=''

  if [ -z "${XMJ_EXTEND_NOTICE_MESSAGE:-}" ]; then
    return 0
  fi

  notice_color="$(xmj_extend_notice_color)"
  printf '\n'
  printf '  %b%s%b\n' "$notice_color" "$XMJ_EXTEND_NOTICE_MESSAGE" "$XMJ_RESET"
}

xmj_extend_collect_entry_scripts() {
  local scripts_dir=''
  local script_path=''

  scripts_dir="$(xmj_extend_scripts_dir)"

  declare -ga XMJ_EXTEND_ENTRY_PATHS=()

  if [ ! -d "$scripts_dir" ]; then
    return 0
  fi

  shopt -s nullglob
  for script_path in "$scripts_dir"/*.sh "$scripts_dir"/*.bash; do
    [ -f "$script_path" ] || continue

    case "$(basename "$script_path")" in
      reserved-slot.sh)
        continue
        ;;
    esac

    XMJ_EXTEND_ENTRY_PATHS+=("$script_path")
  done
  shopt -u nullglob
}

xmj_extend_prompt_input() {
  local prompt="${1:-  扩展脚本 > }"

  printf '%b%s%b' "$XMJ_PINK_SOFT" "$prompt" "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_extend_script_entry_page() {
  local scripts_dir=''
  local script_count='0'
  local index='1'
  local script_path=''
  local display_path=''
  local run_mode=''

  xmj_extend_collect_entry_scripts

  scripts_dir="$(xmj_extend_scripts_dir)"
  script_count="${#XMJ_EXTEND_ENTRY_PATHS[@]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['15']}" 'script entry' 'extend'
  printf '\n'
  xmj_render_fact_line '主入口' "$(xmj_display_path "${XMJ_ROOT_DIR}/xiaomaojuan.sh")"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-${XMJ_ROOT_DIR}/config/xiaomaojuan.conf}")"
  xmj_render_fact_line '扩展目录' "$(xmj_display_path "$scripts_dir")"
  xmj_render_fact_line '可运行脚本' "${script_count} 个"

  if [ "$script_count" -gt 0 ]; then
    printf '\n'
    printf '  %b这里会自动列出 scripts/ 目录里的 .sh / .bash 文件。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'

    for script_path in "${XMJ_EXTEND_ENTRY_PATHS[@]}"; do
      display_path="$(xmj_extend_relative_path "$script_path")"
      run_mode='使用 bash 运行'

      if [ -x "$script_path" ]; then
        run_mode='可直接执行'
      fi

      xmj_render_action_item "$index" "$display_path"
      printf '    %b%s%b\n' "$XMJ_MIST" "$run_mode" "$XMJ_RESET"
      index=$((index + 1))
    done
  else
    printf '\n'
    xmj_render_setting_card \
      '暂无扩展脚本' \
      '把自定义 .sh 文件放进 scripts/ 目录后，这里会自动出现入口。' \
      '18 号位单独保留给 reserved-slot.sh'
  fi

  xmj_render_extend_notice
  printf '\n'
  xmj_render_action_item '0' '返回首页'

  if [ "$script_count" -gt 0 ]; then
    xmj_render_action_footer '输入序号运行脚本，输入 0 返回首页'
  else
    xmj_render_action_footer '输入 0 返回首页'
  fi
}

xmj_extend_export_context() {
  export XMJ_ROOT_DIR
  export XMJ_CONFIG_FILE
  export XMJ_CONFIG_GUIDE_FILE
  export XMJ_SILLYTAVERN_PATH
  export XMJ_BACKUP_DIR
  export XMJ_LOG_DIR
  export XMJ_TAVERN_HOST
  export XMJ_TAVERN_PORT
  export XMJ_TAVERN_ENTRY_PATH
  export XMJ_THEME_MODE
  export XMJ_SCRIPT_NAME
  export XMJ_SCRIPT_AUTHOR
  export XMJ_TARGET_PROJECT
  export XMJ_RUNTIME_ENV
}

xmj_extend_execute_script() {
  local script_path="${1:-}"
  local source_label="${2:-脚本入口}"
  local display_path=''
  local exit_code='0'

  display_path="$(xmj_extend_relative_path "$script_path")"

  if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
    xmj_extend_set_notice 'warn' "未找到脚本：$display_path"
    return 1
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$display_path" 'running script' 'extend'
  printf '\n'
  xmj_render_fact_line '来源页面' "$source_label"
  xmj_render_fact_line '工作目录' "$(xmj_display_path "${XMJ_ROOT_DIR:-.}")"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  printf '  %b下面是脚本原始输出：%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'

  (
    cd "${XMJ_ROOT_DIR:-.}" || exit 1
    xmj_extend_export_context

    if [ -x "$script_path" ]; then
      "$script_path"
    else
      bash "$script_path"
    fi
  )
  exit_code=$?

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  if [ "$exit_code" -eq 0 ]; then
    printf '  %b脚本执行完成。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
    xmj_extend_set_notice 'success' "已执行 $display_path。"
  else
    printf '  %b脚本退出码：%s。%b\n' "$XMJ_WARN" "$exit_code" "$XMJ_RESET"
    xmj_extend_set_notice 'warn' "$display_path 执行失败，退出码为 $exit_code。"
  fi
  xmj_wait_for_enter '按回车返回扩展脚本'
}

xmj_run_extend_script_entry_page() {
  local input=''
  local count='0'
  local index='0'

  xmj_extend_clear_notice

  while true; do
    xmj_render_extend_script_entry_page
    xmj_extend_prompt_input '  脚本入口 > '
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      ''|0)
        xmj_extend_clear_notice
        return 0
        ;;
      *[!0-9]*)
        xmj_extend_set_notice 'warn' '请输入脚本序号，或输入 0 返回首页。'
        ;;
      *)
        count="${#XMJ_EXTEND_ENTRY_PATHS[@]}"
        if [ "$count" -eq 0 ]; then
          xmj_extend_set_notice 'warn' '当前没有可运行的扩展脚本。'
          continue
        fi

        if [ "$input" -lt 1 ] || [ "$input" -gt "$count" ]; then
          xmj_extend_set_notice 'warn' "仅支持输入 1 - $count，或输入 0 返回首页。"
          continue
        fi

        index=$((input - 1))
        xmj_extend_execute_script "${XMJ_EXTEND_ENTRY_PATHS[$index]}" "${XMJ_MENU_LABEL['15']}"
        ;;
    esac
  done
}

xmj_extend_first_line() {
  local text="${1:-}"

  printf '%s' "${text%%$'\n'*}"
}

xmj_extend_command_status() {
  local command_name="${1:-}"
  local version_text=''

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s' '未安装'
    return 0
  fi

  case "$command_name" in
    bash)
      version_text="$(xmj_extend_first_line "$(bash --version 2>/dev/null)")"
      ;;
    git)
      version_text="$(xmj_extend_first_line "$(git --version 2>/dev/null)")"
      ;;
    curl)
      version_text="$(xmj_extend_first_line "$(curl --version 2>/dev/null)")"
      ;;
    zip)
      version_text="$(xmj_extend_first_line "$(zip -v 2>/dev/null)")"
      ;;
    unzip)
      version_text="$(xmj_extend_first_line "$(unzip -v 2>/dev/null)")"
      ;;
    python3)
      version_text="$(xmj_extend_first_line "$(python3 --version 2>/dev/null)")"
      ;;
    python)
      version_text="$(xmj_extend_first_line "$(python --version 2>/dev/null)")"
      ;;
    node)
      version_text="$(xmj_extend_first_line "$(node --version 2>/dev/null)")"
      ;;
    npm)
      version_text="$(xmj_extend_first_line "$(npm --version 2>/dev/null)")"
      ;;
    termux-reload-settings)
      version_text="$(command -v termux-reload-settings 2>/dev/null)"
      ;;
    *)
      version_text="$(command -v "$command_name" 2>/dev/null)"
      ;;
  esac

  if [ -n "$version_text" ]; then
    printf '%s' "已安装 · $version_text"
    return 0
  fi

  printf '%s' "已安装 · $(command -v "$command_name" 2>/dev/null)"
}

xmj_extend_archive_capability_text() {
  local python_cmd=''

  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    printf '%s' 'zip / unzip 已就绪'
    return 0
  fi

  python_cmd="$(xmj_maintenance_python_cmd)"
  if [ -n "$python_cmd" ]; then
    printf '%s' "缺少 zip / unzip，当前会回退到 $python_cmd"
    return 0
  fi

  printf '%s' '未就绪'
}

xmj_run_extend_toolbox_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['16']}" 'tool box' 'extend'
  printf '\n'
  xmj_render_page_intro \
    '每次进入页面时都会重新检测当前终端的常用命令状态。' \
    '缺失项可以回到 11 - 13 继续补装或修复。'
  printf '\n'
  xmj_render_fact_line 'bash' "$(xmj_extend_command_status 'bash')"
  xmj_render_fact_line 'git' "$(xmj_extend_command_status 'git')"
  xmj_render_fact_line 'curl' "$(xmj_extend_command_status 'curl')"
  xmj_render_fact_line 'zip' "$(xmj_extend_command_status 'zip')"
  xmj_render_fact_line 'unzip' "$(xmj_extend_command_status 'unzip')"
  xmj_render_fact_line 'python3' "$(xmj_extend_command_status 'python3')"
  xmj_render_fact_line 'python' "$(xmj_extend_command_status 'python')"
  xmj_render_fact_line 'node' "$(xmj_extend_command_status 'node')"
  xmj_render_fact_line 'npm' "$(xmj_extend_command_status 'npm')"
  xmj_render_fact_line 'termux-reload-settings' "$(xmj_extend_command_status 'termux-reload-settings')"
  printf '\n'
  xmj_render_fact_line '备份打包能力' "$(xmj_extend_archive_capability_text)"
  xmj_render_fact_line '酒馆目录' "$(xmj_dir_state "${XMJ_SILLYTAVERN_PATH:-}" '已发现' '待确认')"
  xmj_render_page_footer '按回车返回首页'
}

xmj_extend_reserved_slot_state() {
  local slot_path=''

  slot_path="$(xmj_extend_reserved_slot_path)"
  if [ -f "$slot_path" ]; then
    printf '%s' '已创建'
    return 0
  fi

  printf '%s' '未创建'
}

xmj_run_extend_followup_page() {
  local scripts_dir=''
  local slot_path=''

  xmj_extend_collect_entry_scripts
  scripts_dir="$(xmj_extend_scripts_dir)"
  slot_path="$(xmj_extend_reserved_slot_path)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['17']}" 'follow-up plan' 'extend'
  printf '\n'
  xmj_render_page_intro \
    '这里整理扩展区已经接好的入口，以及后续适合继续往里加的内容。' \
    '这页本身不执行命令，主要把扩展方向说清楚。'
  printf '\n'
  xmj_render_fact_line '扩展目录状态' "$(xmj_dir_state "$scripts_dir" '已创建' '未创建')"
  xmj_render_fact_line '脚本入口数量' "${#XMJ_EXTEND_ENTRY_PATHS[@]} 个"
  xmj_render_fact_line '预留空位状态' "$(xmj_extend_reserved_slot_state)"
  xmj_render_fact_line '预留脚本路径' "$(xmj_display_path "$slot_path")"
  printf '\n'
  xmj_render_setting_card \
    '现在已接入' \
    '15 号位会扫描 scripts/ 并直接运行自定义脚本。' \
    '16 号位会实时检测环境工具状态'
  printf '\n'
  xmj_render_setting_card \
    '适合继续追加' \
    '把常用维护动作拆成独立 .sh，放进 scripts/ 目录即可。' \
    '18 号位更适合挂一次性或私有命令'
  printf '\n'
  xmj_render_setting_card \
    '后续方向' \
    '06 教程说明、20 酒馆设置这类页面仍可继续补业务逻辑。' \
    '扩展区现在已经不是纯占位页'
  xmj_render_page_footer '按回车返回首页'
}

xmj_extend_create_reserved_template() {
  local scripts_dir=''
  local slot_path=''

  scripts_dir="$(xmj_extend_scripts_dir)"
  slot_path="$(xmj_extend_reserved_slot_path)"

  if ! mkdir -p "$scripts_dir" 2>/dev/null; then
    xmj_extend_set_notice 'warn' "无法创建扩展目录：$(xmj_display_path "$scripts_dir")"
    return 1
  fi

  if [ -e "$slot_path" ]; then
    xmj_extend_set_notice 'warn' '预留脚本已经存在，未重复生成。'
    return 1
  fi

  if ! cat > "$slot_path" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

set -u

printf '\n'
printf 'reserved slot template is running.\n'
printf 'root: %s\n' "${XMJ_ROOT_DIR:-unknown}"
printf 'sillytavern: %s\n' "${XMJ_SILLYTAVERN_PATH:-unknown}"
printf '\n'
printf 'Edit scripts/reserved-slot.sh to add your own commands.\n'
printf '\n'
EOF
  then
    xmj_extend_set_notice 'warn' '生成预留脚本模板失败。'
    return 1
  fi

  chmod +x "$slot_path" 2>/dev/null || true
  xmj_extend_set_notice 'success' '已生成 scripts/reserved-slot.sh，可以直接改成自己的脚本。'
  return 0
}

xmj_render_extend_reserved_page() {
  local slot_path=''
  local slot_state=''

  slot_path="$(xmj_extend_reserved_slot_path)"
  slot_state="$(xmj_extend_reserved_slot_state)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['18']}" 'reserved slot' 'extend'
  printf '\n'
  xmj_render_fact_line '预留脚本' "$slot_state"
  xmj_render_fact_line '脚本路径' "$(xmj_display_path "$slot_path")"
  xmj_render_fact_line '工作目录' "$(xmj_display_path "${XMJ_ROOT_DIR:-.}")"
  printf '\n'

  if [ -f "$slot_path" ]; then
    xmj_render_setting_card \
      '1 · 运行预留脚本' \
      '适合放你自己的临时命令、一键修补或私有流程。' \
      '执行时会继承小猫卷的基础环境变量'
  else
    xmj_render_setting_card \
      '1 · 生成模板' \
      '会创建 scripts/reserved-slot.sh，后续你可以直接往里写命令。' \
      '不会覆盖已经存在的文件'
  fi

  xmj_render_extend_notice
  printf '\n'
  xmj_render_action_item '1' "$( [ -f "$slot_path" ] && printf '%s' '运行预留脚本' || printf '%s' '生成预留模板' )"
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 继续，输入 0 返回首页'
}

xmj_run_extend_reserved_page() {
  local input=''
  local slot_path=''

  xmj_extend_clear_notice

  while true; do
    slot_path="$(xmj_extend_reserved_slot_path)"
    xmj_render_extend_reserved_page
    xmj_extend_prompt_input '  预留空位 > '
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      ''|0)
        xmj_extend_clear_notice
        return 0
        ;;
      1)
        if [ -f "$slot_path" ]; then
          xmj_extend_execute_script "$slot_path" "${XMJ_MENU_LABEL['18']}"
        else
          xmj_extend_create_reserved_template
        fi
        ;;
      *)
        xmj_extend_set_notice 'warn' '仅支持输入 1 或 0。'
        ;;
    esac
  done
}
