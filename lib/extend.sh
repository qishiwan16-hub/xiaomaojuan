xmj_extend_registry_file() {
  printf '%s' "${XMJ_CONFIG_DIR:-${XMJ_ROOT_DIR:-.}/config}/extend-scripts.tsv"
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

xmj_extend_prompt_input() {
  local prompt="${1:-  扩展脚本 > }"

  printf '%b%s%b' "$XMJ_PINK_SOFT" "$prompt" "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_extend_trim() {
  local text="${1:-}"

  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  printf '%s' "$text"
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

xmj_extend_display_script_path() {
  printf '%s' "$(xmj_display_path "$(xmj_extend_relative_path "${1:-}")")"
}

xmj_extend_ensure_registry_file() {
  local registry_file=''
  local registry_dir=''

  registry_file="$(xmj_extend_registry_file)"
  registry_dir="$(dirname "$registry_file")"

  if ! mkdir -p "$registry_dir" 2>/dev/null; then
    xmj_extend_set_notice 'warn' '猫猫没法准备扩展脚本清单喵。'
    return 1
  fi

  if [ ! -f "$registry_file" ] && ! : > "$registry_file" 2>/dev/null; then
    xmj_extend_set_notice 'warn' '扩展脚本清单写不进去喵。'
    return 1
  fi

  return 0
}

xmj_extend_load_registry() {
  local registry_file=''
  local name=''
  local path=''

  declare -ga XMJ_EXTEND_SCRIPT_NAMES=()
  declare -ga XMJ_EXTEND_SCRIPT_PATHS=()

  if ! xmj_extend_ensure_registry_file; then
    return 1
  fi

  registry_file="$(xmj_extend_registry_file)"

  while IFS=$'\t' read -r name path; do
    [ -n "$name" ] || continue
    [ -n "$path" ] || continue
    XMJ_EXTEND_SCRIPT_NAMES+=("$name")
    XMJ_EXTEND_SCRIPT_PATHS+=("$path")
  done < "$registry_file"

  return 0
}

xmj_extend_write_registry() {
  local registry_file=''
  local index='0'

  if ! xmj_extend_ensure_registry_file; then
    return 1
  fi

  registry_file="$(xmj_extend_registry_file)"

  : > "$registry_file" || {
    xmj_extend_set_notice 'warn' '猫猫写不回扩展脚本清单喵。'
    return 1
  }

  for ((index = 0; index < ${#XMJ_EXTEND_SCRIPT_NAMES[@]}; index += 1)); do
    printf '%s\t%s\n' "${XMJ_EXTEND_SCRIPT_NAMES[$index]}" "${XMJ_EXTEND_SCRIPT_PATHS[$index]}" >> "$registry_file"
  done

  return 0
}

xmj_extend_find_index_by_name() {
  local target_name="${1:-}"
  local index='0'

  for ((index = 0; index < ${#XMJ_EXTEND_SCRIPT_NAMES[@]}; index += 1)); do
    if [ "${XMJ_EXTEND_SCRIPT_NAMES[$index]}" = "$target_name" ]; then
      printf '%s' "$index"
      return 0
    fi
  done

  printf '%s' '-1'
}

xmj_extend_find_index_by_path() {
  local target_path="${1:-}"
  local index='0'

  for ((index = 0; index < ${#XMJ_EXTEND_SCRIPT_PATHS[@]}; index += 1)); do
    if [ "${XMJ_EXTEND_SCRIPT_PATHS[$index]}" = "$target_path" ]; then
      printf '%s' "$index"
      return 0
    fi
  done

  printf '%s' '-1'
}

xmj_extend_normalize_script_path() {
  local raw_path=''
  local candidate=''
  local resolved_dir=''
  local file_name=''

  raw_path="$(xmj_extend_trim "${1:-}")"
  if [ -z "$raw_path" ]; then
    printf '%s' ''
    return 0
  fi

  candidate="$(xmj_expand_path "$raw_path")"

  case "$candidate" in
    /*)
      ;;
    *)
      candidate="${XMJ_ROOT_DIR:-.}/$candidate"
      ;;
  esac

  if [ -f "$candidate" ]; then
    resolved_dir="$(cd "$(dirname "$candidate")" 2>/dev/null && pwd)"
    file_name="$(basename "$candidate")"
    if [ -n "$resolved_dir" ]; then
      candidate="$resolved_dir/$file_name"
    fi
  fi

  printf '%s' "$candidate"
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
  local script_name="${1:-}"
  local script_path="${2:-}"
  local exit_code='0'

  if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
    xmj_extend_set_notice 'warn' "猫猫没找到「$script_name」的脚本喵。"
    return 1
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$script_name" 'tool launcher' 'extend'
  printf '\n'
  printf '  %b猫猫帮你把这个工具点起来喵。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b%s%b\n' "$XMJ_MIST" "$(xmj_extend_display_script_path "$script_path")" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
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
    printf '  %b这个工具跑完啦。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
    xmj_extend_set_notice 'success' "猫猫已经帮你启用「$script_name」啦。"
  else
    printf '  %b这个工具中途停下了，退出码是 %s。%b\n' "$XMJ_WARN" "$exit_code" "$XMJ_RESET"
    xmj_extend_set_notice 'warn' "「$script_name」这次没有顺利跑完喵。"
  fi
  xmj_wait_for_enter '按回车回到脚本入口'
}

xmj_render_extend_script_entry_page() {
  local count='0'
  local index='0'
  local status_text=''

  xmj_extend_load_registry || true
  count="${#XMJ_EXTEND_SCRIPT_NAMES[@]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['15']}" 'tool launcher' 'extend'
  printf '\n'

  if [ "$count" -eq 0 ]; then
    xmj_render_setting_card \
      '猫猫还没记住别的工具喵' \
      '去 16 号位填名字和路径，我就把它挂到这里。' \
      ''
  else
    for ((index = 0; index < count; index += 1)); do
      status_text='能启动'
      if [ ! -f "${XMJ_EXTEND_SCRIPT_PATHS[$index]}" ]; then
        status_text='脚本不见了'
      fi

      xmj_render_action_item "$((index + 1))" "${XMJ_EXTEND_SCRIPT_NAMES[$index]}"
      printf '    %b%s · %s%b\n' \
        "$XMJ_MIST" \
        "$(xmj_extend_display_script_path "${XMJ_EXTEND_SCRIPT_PATHS[$index]}")" \
        "$status_text" \
        "$XMJ_RESET"
    done
  fi

  xmj_render_extend_notice
  printf '\n'
  xmj_render_action_item '0' '返回首页'

  if [ "$count" -gt 0 ]; then
    xmj_render_action_footer '输入序号就能启用工具，输入 0 回首页'
  else
    xmj_render_action_footer '先去 16 号位记一个工具，或者输入 0 回首页'
  fi
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
        xmj_extend_set_notice 'warn' '猫猫只认序号喵。'
        ;;
      *)
        count="${#XMJ_EXTEND_SCRIPT_NAMES[@]}"
        if [ "$count" -eq 0 ]; then
          xmj_extend_set_notice 'warn' '现在还没有可启动的工具喵。'
          continue
        fi

        if [ "$input" -lt 1 ] || [ "$input" -gt "$count" ]; then
          xmj_extend_set_notice 'warn' "猫猫这里只摆了 1 - $count 号喵。"
          continue
        fi

        index=$((input - 1))
        xmj_extend_execute_script "${XMJ_EXTEND_SCRIPT_NAMES[$index]}" "${XMJ_EXTEND_SCRIPT_PATHS[$index]}"
        ;;
    esac
  done
}

xmj_render_extend_add_page() {
  local count='0'
  local index='0'

  xmj_extend_load_registry || true
  count="${#XMJ_EXTEND_SCRIPT_NAMES[@]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['16']}" 'add script' 'extend'
  printf '\n'

  if [ "$count" -eq 0 ]; then
    xmj_render_setting_card \
      '还没有登记好的工具喵' \
      '按 1 开始新增，名字和脚本路径都告诉猫猫就行。' \
      ''
  else
    xmj_render_setting_card \
      '猫猫已经记住这些工具啦' \
      '要继续加新的，按 1 就好。' \
      ''
    printf '\n'

    for ((index = 0; index < count; index += 1)); do
      printf '  %b· %s%b\n' "$XMJ_WHITE" "${XMJ_EXTEND_SCRIPT_NAMES[$index]}" "$XMJ_RESET"
      printf '    %b%s%b\n' "$XMJ_MIST" "$(xmj_extend_display_script_path "${XMJ_EXTEND_SCRIPT_PATHS[$index]}")" "$XMJ_RESET"
    done
  fi

  xmj_render_extend_notice
  printf '\n'
  xmj_render_action_item '1' '新增一条脚本登记'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 开始新增，输入 0 回首页'
}

xmj_extend_add_entry() {
  local script_name=''
  local script_path=''
  local normalized_path=''
  local name_index='-1'
  local path_index='-1'

  printf '\n'
  xmj_extend_prompt_input '  脚本名字 > '
  script_name="$(xmj_extend_trim "${XMJ_LAST_INPUT:-}")"
  if [ -z "$script_name" ]; then
    xmj_extend_set_notice 'warn' '名字空空的，猫猫先不记喵。'
    return 1
  fi

  printf '\n'
  xmj_extend_prompt_input '  脚本路径 > '
  script_path="$(xmj_extend_trim "${XMJ_LAST_INPUT:-}")"
  normalized_path="$(xmj_extend_normalize_script_path "$script_path")"

  if [ -z "$normalized_path" ]; then
    xmj_extend_set_notice 'warn' '路径没有填，猫猫没法登记喵。'
    return 1
  fi

  if [ ! -f "$normalized_path" ]; then
    xmj_extend_set_notice 'warn' '这个路径下没有脚本文件喵。'
    return 1
  fi

  case "$script_name$normalized_path" in
    *$'\t'*)
      xmj_extend_set_notice 'warn' '名字和路径里先别塞奇怪空白符喵。'
      return 1
      ;;
  esac

  case "$script_name$normalized_path" in
    *$'\n'*|*$'\r'*)
      xmj_extend_set_notice 'warn' '名字和路径里先别塞奇怪空白符喵。'
      return 1
      ;;
  esac

  xmj_extend_load_registry || return 1

  name_index="$(xmj_extend_find_index_by_name "$script_name")"
  path_index="$(xmj_extend_find_index_by_path "$normalized_path")"

  if [ "$name_index" -ge 0 ]; then
    XMJ_EXTEND_SCRIPT_PATHS[$name_index]="$normalized_path"
    if ! xmj_extend_write_registry; then
      return 1
    fi
    xmj_extend_set_notice 'success' "猫猫把「$script_name」的路径更新好啦。"
    return 0
  fi

  if [ "$path_index" -ge 0 ]; then
    XMJ_EXTEND_SCRIPT_NAMES[$path_index]="$script_name"
    if ! xmj_extend_write_registry; then
      return 1
    fi
    xmj_extend_set_notice 'success' '这条脚本我已经记过啦，名字帮你改新了。'
    return 0
  fi

  XMJ_EXTEND_SCRIPT_NAMES+=("$script_name")
  XMJ_EXTEND_SCRIPT_PATHS+=("$normalized_path")

  if ! xmj_extend_write_registry; then
    return 1
  fi

  xmj_extend_set_notice 'success' "猫猫记住「$script_name」啦，去 15 号位就能点它。"
}

xmj_run_extend_toolbox_page() {
  local input=''

  xmj_extend_clear_notice

  while true; do
    xmj_render_extend_add_page
    xmj_extend_prompt_input '  增加脚本 > '
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      ''|0)
        xmj_extend_clear_notice
        return 0
        ;;
      1)
        xmj_extend_add_entry
        ;;
      *)
        xmj_extend_set_notice 'warn' '猫猫这里只收 1 或 0 喵。'
        ;;
    esac
  done
}

xmj_render_extend_delete_page() {
  local count='0'
  local index='0'

  xmj_extend_load_registry || true
  count="${#XMJ_EXTEND_SCRIPT_NAMES[@]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['17']}" 'delete script' 'extend'
  printf '\n'

  if [ "$count" -eq 0 ]; then
    xmj_render_setting_card \
      '现在没有可取消的登记喵' \
      '猫猫这边还是空空的。' \
      ''
  else
    xmj_render_setting_card \
      '选一个就会取消登记喵' \
      '只会从小猫卷入口里拿掉，不会碰原脚本文件。' \
      ''
    printf '\n'

    for ((index = 0; index < count; index += 1)); do
      xmj_render_action_item "$((index + 1))" "${XMJ_EXTEND_SCRIPT_NAMES[$index]}"
      printf '    %b%s%b\n' "$XMJ_MIST" "$(xmj_extend_display_script_path "${XMJ_EXTEND_SCRIPT_PATHS[$index]}")" "$XMJ_RESET"
    done
  fi

  xmj_render_extend_notice
  printf '\n'
  xmj_render_action_item '0' '返回首页'

  if [ "$count" -gt 0 ]; then
    xmj_render_action_footer '输入序号取消登记，输入 0 回首页'
  else
    xmj_render_action_footer '输入 0 回首页'
  fi
}

xmj_extend_remove_entry() {
  local remove_index="${1:-0}"
  local index='0'
  local removed_name=''
  local -a next_names=()
  local -a next_paths=()

  removed_name="${XMJ_EXTEND_SCRIPT_NAMES[$remove_index]}"

  for ((index = 0; index < ${#XMJ_EXTEND_SCRIPT_NAMES[@]}; index += 1)); do
    if [ "$index" -eq "$remove_index" ]; then
      continue
    fi

    next_names+=("${XMJ_EXTEND_SCRIPT_NAMES[$index]}")
    next_paths+=("${XMJ_EXTEND_SCRIPT_PATHS[$index]}")
  done

  XMJ_EXTEND_SCRIPT_NAMES=("${next_names[@]}")
  XMJ_EXTEND_SCRIPT_PATHS=("${next_paths[@]}")

  if ! xmj_extend_write_registry; then
    return 1
  fi

  xmj_extend_set_notice 'success' "猫猫把「$removed_name」从入口里拿下来了，原脚本还在喵。"
}

xmj_run_extend_followup_page() {
  local input=''
  local count='0'
  local index='0'

  xmj_extend_clear_notice

  while true; do
    xmj_render_extend_delete_page
    xmj_extend_prompt_input '  删除脚本 > '
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      ''|0)
        xmj_extend_clear_notice
        return 0
        ;;
      *[!0-9]*)
        xmj_extend_set_notice 'warn' '猫猫只认序号喵。'
        ;;
      *)
        count="${#XMJ_EXTEND_SCRIPT_NAMES[@]}"
        if [ "$count" -eq 0 ]; then
          xmj_extend_set_notice 'warn' '现在没有能取消的登记喵。'
          continue
        fi

        if [ "$input" -lt 1 ] || [ "$input" -gt "$count" ]; then
          xmj_extend_set_notice 'warn' "猫猫这里只摆了 1 - $count 号喵。"
          continue
        fi

        index=$((input - 1))
        xmj_extend_remove_entry "$index"
        ;;
    esac
  done
}

xmj_run_extend_reserved_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['18']}" 'coming soon' 'extend'
  printf '\n'
  xmj_render_setting_card \
    '这里先空着喵' \
    '猫猫还没往里面塞新东西，之后再慢慢长出来。' \
    ''
  xmj_render_page_footer '按回车回首页'
}
