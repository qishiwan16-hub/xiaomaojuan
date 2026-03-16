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

xmj_render_char_width() {
  local ch="${1:-}"

  case "$ch" in
    $'\t')
      printf '%s' '4'
      ;;
    ' '|[!-~])
      printf '%s' '1'
      ;;
    *)
      printf '%s' '2'
      ;;
  esac
}

xmj_render_text_width() {
  local text="${1:-}"
  local width='0'
  local i='0'
  local ch=''
  local ch_width='0'

  for ((i = 0; i < ${#text}; i++)); do
    ch="${text:i:1}"
    ch_width="$(xmj_render_char_width "$ch")"
    width=$((width + ch_width))
  done

  printf '%s' "$width"
}

xmj_render_trim_leading_spaces() {
  local text="${1:-}"

  text="${text#"${text%%[![:space:]]*}"}"
  printf '%s' "$text"
}

xmj_render_find_last_break_index() {
  local text="${1:-}"
  local break_index='-1'
  local i='0'
  local ch=''

  for ((i = 0; i < ${#text}; i++)); do
    ch="${text:i:1}"
    case "$ch" in
      ' '|/|\\|:|,|.|-|_|'|'|')'|'('|']'|'[')
        break_index="$i"
        ;;
    esac
  done

  printf '%s' "$break_index"
}

xmj_render_wrap_text() {
  local text="${1:-}"
  local max_width="${2:-40}"
  local current=''
  local current_width='0'
  local last_break_index='-1'
  local line=''
  local remainder=''
  local break_char=''
  local i='0'
  local ch=''
  local ch_width='0'

  if [ "$max_width" -lt 8 ]; then
    max_width='8'
  fi

  text="${text//$'\r'/}"
  if [ -z "$text" ]; then
    printf '\n'
    return 0
  fi

  for ((i = 0; i < ${#text}; i++)); do
    ch="${text:i:1}"

    if [ "$ch" = $'\n' ]; then
      printf '%s\n' "$current"
      current=''
      current_width='0'
      last_break_index='-1'
      continue
    fi

    current+="$ch"
    ch_width="$(xmj_render_char_width "$ch")"
    current_width=$((current_width + ch_width))

    case "$ch" in
      ' '|/|\\|:|,|.|-|_|'|'|')'|'('|']'|'[')
        last_break_index="$(( ${#current} - 1 ))"
        ;;
    esac

    if [ "$current_width" -le "$max_width" ]; then
      continue
    fi

    if [ "$last_break_index" -ge 0 ]; then
      break_char="${current:$last_break_index:1}"
      if [ "$break_char" = ' ' ]; then
        line="${current:0:$last_break_index}"
        remainder="${current:$((last_break_index + 1))}"
      else
        line="${current:0:$((last_break_index + 1))}"
        remainder="${current:$((last_break_index + 1))}"
      fi
      remainder="$(xmj_render_trim_leading_spaces "$remainder")"
    else
      line="${current:0:$(( ${#current} - 1 ))}"
      remainder="${current:$(( ${#current} - 1 ))}"
    fi

    if [ -z "$line" ]; then
      line="$current"
      remainder=''
    fi

    printf '%s\n' "$line"
    current="$remainder"
    current_width="$(xmj_render_text_width "$current")"
    last_break_index="$(xmj_render_find_last_break_index "$current")"
  done

  printf '%s\n' "$current"
}

xmj_render_print_wrapped_text() {
  local indent="${1:-  }"
  local color="${2:-$XMJ_WHITE}"
  local text="${3:-}"
  local panel_width='0'
  local indent_width='0'
  local content_width='0'
  local line=''

  if [ -z "$text" ]; then
    return 0
  fi

  panel_width="$(xmj_panel_width)"
  indent_width="$(xmj_render_text_width "$indent")"
  content_width=$((panel_width - indent_width))
  if [ "$content_width" -lt 8 ]; then
    content_width='8'
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s%b%s%b\n' "$indent" "$color" "$line" "$XMJ_RESET"
  done < <(xmj_render_wrap_text "$text" "$content_width")
}

xmj_render_print_prefixed_text() {
  local prefix="${1:-}"
  local prefix_color="${2:-$XMJ_WHITE}"
  local text_color="${3:-$XMJ_WHITE}"
  local text="${4:-}"
  local panel_width='0'
  local prefix_width='0'
  local content_width='0'
  local continuation_indent=''
  local line=''
  local first_line='1'

  panel_width="$(xmj_panel_width)"
  prefix_width="$(xmj_render_text_width "$prefix")"
  content_width=$((panel_width - prefix_width))
  if [ "$content_width" -lt 8 ]; then
    content_width='8'
  fi

  continuation_indent="$(xmj_repeat_char ' ' "$prefix_width")"
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$first_line" = '1' ]; then
      printf '%b%s%b%b%s%b\n' "$prefix_color" "$prefix" "$XMJ_RESET" "$text_color" "$line" "$XMJ_RESET"
      first_line='0'
    else
      printf '%s%b%s%b\n' "$continuation_indent" "$text_color" "$line" "$XMJ_RESET"
    fi
  done < <(xmj_render_wrap_text "$text" "$content_width")
}

xmj_render_fact_line() {
  local label="${1:-}"
  local value="${2:-}"

  xmj_render_print_prefixed_text "  ${label}: " "$XMJ_BLUE_SOFT" "$XMJ_WHITE" "$value"
}

xmj_render_path_block() {
  local label="${1:-}"
  local path_value="${2:-}"
  local state_value="${3:-}"

  xmj_render_print_wrapped_text '  ' "$XMJ_BLUE_SOFT" "$label"
  xmj_render_print_prefixed_text '    path: ' "$XMJ_MIST" "$XMJ_WHITE" "$path_value"
  xmj_render_print_prefixed_text '    state: ' "$XMJ_MIST" "$XMJ_CREAM" "$state_value"
}

xmj_render_page_intro() {
  local primary_text="${1:-}"
  local secondary_text="${2:-}"

  if [ -n "$primary_text" ]; then
    xmj_render_print_wrapped_text '  ' "$XMJ_WHITE" "$primary_text"
  fi

  if [ -n "$secondary_text" ]; then
    xmj_render_print_wrapped_text '  ' "$XMJ_MIST" "$secondary_text"
  fi
}

xmj_render_action_item() {
  local key="${1:-}"
  local label="${2:-}"

  xmj_render_print_prefixed_text "  [${key}] | " "$XMJ_PINK" "$XMJ_WHITE" "$label"
}

xmj_render_setting_card() {
  local title="${1:-}"
  local description="${2:-}"
  local status_text="${3:-}"

  xmj_render_print_prefixed_text '  ♡ ' "$XMJ_PINK" "$XMJ_PINK" "$title"

  if [ -n "$description" ]; then
    xmj_render_print_wrapped_text '    ' "$XMJ_WHITE" "$description"
  fi

  if [ -n "$status_text" ]; then
    xmj_render_print_wrapped_text '    ' "$XMJ_MIST" "$status_text"
  fi
}

xmj_render_notice_line() {
  local notice_color=''

  if [ -z "${XMJ_FONT_ACTION_MESSAGE:-}" ]; then
    return 0
  fi

  notice_color="$(xmj_font_notice_color)"
  printf '\n'
  xmj_render_print_wrapped_text '  ' "$notice_color" "$XMJ_FONT_ACTION_MESSAGE"
}

xmj_update_stage_order() {
  case "${1:-}" in
    prepare) printf '%s' '1' ;;
    env|repo) printf '%s' '2' ;;
    backup) printf '%s' '3' ;;
    local) printf '%s' '4' ;;
    pull) printf '%s' '5' ;;
    deps) printf '%s' '6' ;;
    recover) printf '%s' '7' ;;
    restore) printf '%s' '8' ;;
    done) printf '%s' '9' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_update_stage_label() {
  case "${1:-}" in
    prepare) printf '%s' '准备中' ;;
    env|repo) printf '%s' '检查环境' ;;
    backup) printf '%s' '自动备份' ;;
    local) printf '%s' '整理本地改动' ;;
    pull) printf '%s' '拉取更新' ;;
    deps) printf '%s' '同步依赖' ;;
    recover) printf '%s' '恢复备份' ;;
    restore) printf '%s' '放回本地改动' ;;
    done) printf '%s' '更新完成' ;;
    *) printf '%s' '更新中' ;;
  esac
}

xmj_update_display_stage() {
  case "${1:-}" in
    repo) printf '%s' 'env' ;;
    *) printf '%s' "${1:-prepare}" ;;
  esac
}

xmj_render_update_stage_line() {
  local stage="${1:-}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local stage_order='0'
  local current_order='0'
  local marker='·'
  local state_text='等待中'
  local color="$XMJ_MIST"

  stage_order="$(xmj_update_stage_order "$stage")"
  current_order="$(xmj_update_stage_order "$current_stage")"

  if [ "$stage_order" -lt "$current_order" ]; then
    marker='✓'
    state_text='已完成'
    color="$XMJ_CREAM"
  elif [ "$stage_order" -eq "$current_order" ]; then
    case "$stage_mode" in
      failure)
        marker='✕'
        state_text='失败'
        color="$XMJ_WARN"
        ;;
      success)
        marker='✓'
        state_text='已完成'
        color="$XMJ_CREAM"
        ;;
      *)
        marker='➜'
        state_text='进行中'
        color="$XMJ_PINK"
        ;;
    esac
  fi

  printf '  %b%s%b %b%s%b %b·%b %b%s%b\n' \
    "$color" "$marker" "$XMJ_RESET" \
    "$XMJ_WHITE" "$(xmj_update_stage_label "$stage")" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$color" "$state_text" "$XMJ_RESET"
}

xmj_render_update_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理更新步骤。}"
  local stage_for_display='prepare'

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro \
    '安装更新进行中，详细命令会悄悄写进日志本。' \
    '前台只保留简洁阶段提示。'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_update_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-当前已是最新版本。}"
  local detail_text="${4:-}"
  local before_commit="${6:-}"
  local after_commit="${7:-}"
  local result_title='更新完成'
  local result_intro='猫猫已经把安装更新整理好了。'
  local result_hint=''
  local stage_mode='success'
  local stage_for_display='done'

  if [ "$result_mode" = 'failure' ]; then
    result_title='更新失败'
    result_intro='这次更新没有顺利完成。'
    result_hint='需要时可温和查看日志。'
    stage_mode='failure'
  fi

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro "$result_intro" "$result_hint"
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"

  if [ "$result_mode" = 'success' ] \
    && [ -n "$before_commit" ] \
    && [ -n "$after_commit" ] \
    && [ "$before_commit" != "$after_commit" ]; then
    printf '  %b版本变化%b：%b%s → %s%b\n' \
      "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$before_commit" "$after_commit" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"

  if [ -n "${XMJ_UPDATE_BACKUP_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '自动备份' "$(xmj_display_path "$XMJ_UPDATE_BACKUP_FILE")"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_reinstall_stage_order() {
  case "${1:-}" in
    prepare) printf '%s' '1' ;;
    env) printf '%s' '2' ;;
    backup) printf '%s' '3' ;;
    remove) printf '%s' '4' ;;
    install) printf '%s' '5' ;;
    deps) printf '%s' '6' ;;
    recover) printf '%s' '7' ;;
    done) printf '%s' '8' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_reinstall_stage_label() {
  case "${1:-}" in
    prepare) printf '%s' '准备中' ;;
    env) printf '%s' '检查环境' ;;
    backup) printf '%s' '自动备份' ;;
    remove) printf '%s' '卸载旧目录' ;;
    install) printf '%s' '重新安装' ;;
    deps) printf '%s' '同步依赖' ;;
    recover) printf '%s' '恢复备份' ;;
    done) printf '%s' '完成' ;;
    *) printf '%s' '卸载重装' ;;
  esac
}

xmj_render_reinstall_stage_line() {
  local stage="${1:-prepare}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local stage_order='0'
  local current_order='0'
  local marker='·'
  local state_text='等待中'
  local color="$XMJ_MIST"

  stage_order="$(xmj_reinstall_stage_order "$stage")"
  current_order="$(xmj_reinstall_stage_order "$current_stage")"

  if [ "$stage_order" -lt "$current_order" ]; then
    marker='✓'
    state_text='已完成'
    color="$XMJ_CREAM"
  elif [ "$stage_order" -eq "$current_order" ]; then
    case "$stage_mode" in
      failure)
        marker='✕'
        state_text='失败'
        color="$XMJ_WARN"
        ;;
      success)
        marker='✓'
        state_text='已完成'
        color="$XMJ_CREAM"
        ;;
      *)
        marker='➜'
        state_text='进行中'
        color="$XMJ_PINK"
        ;;
    esac
  fi

  printf '  %b%s%b %b%s%b %b·%b %b%s%b\n' \
    "$color" "$marker" "$XMJ_RESET" \
    "$XMJ_WHITE" "$(xmj_reinstall_stage_label "$stage")" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$color" "$state_text" "$XMJ_RESET"
}

xmj_render_reinstall_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理卸载重装步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro \
    '卸载重装进行中，详细命令会悄悄写进日志本。' \
    '前台只保留简洁阶段提示，避免把输出直接刷满。'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 卸载重装进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_reinstall_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'remove' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'install' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'done' "$current_stage" "$stage_mode"

  if [ -n "${XMJ_REINSTALL_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_REINSTALL_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_reinstall_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-卸载重装已完成。}"
  local detail_text="${4:-}"
  local result_title='卸载重装完成'
  local result_intro='猫猫已经把卸载重装整理好了。'
  local result_hint=''
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='卸载重装失败'
    result_intro='这次卸载重装没有顺利完成。'
    result_hint='需要时可温和查看日志。'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro "$result_intro" "$result_hint"
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 卸载重装进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_reinstall_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'remove' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'install' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'done' "$current_stage" "$stage_mode"

  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_REINSTALL_AFTER_VERSION:-未知}"

  if [ -n "${XMJ_REINSTALL_BACKUP_FILE:-}" ]; then
    xmj_render_fact_line '自动备份' "$(xmj_display_path "$XMJ_REINSTALL_BACKUP_FILE")"
  fi

  if [ -n "${XMJ_REINSTALL_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_REINSTALL_LOG_FILE")"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_launch_stage_order() {
  case "${1:-}" in
    prepare) printf '%s' '1' ;;
    env) printf '%s' '2' ;;
    boot) printf '%s' '3' ;;
    running) printf '%s' '4' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_launch_stage_label() {
  case "${1:-}" in
    prepare) printf '%s' '准备启动' ;;
    env) printf '%s' '检查环境' ;;
    boot) printf '%s' '启动中' ;;
    running) printf '%s' '运行中' ;;
    *) printf '%s' '启动中' ;;
  esac
}

xmj_render_launch_stage_line() {
  local stage="${1:-prepare}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local stage_order='0'
  local current_order='0'
  local marker='·'
  local state_text='等待中'
  local color="$XMJ_MIST"

  stage_order="$(xmj_launch_stage_order "$stage")"
  current_order="$(xmj_launch_stage_order "$current_stage")"

  if [ "$stage_order" -lt "$current_order" ]; then
    marker='✓'
    state_text='已完成'
    color="$XMJ_CREAM"
  elif [ "$stage_order" -eq "$current_order" ]; then
    case "$stage_mode" in
      failure)
        marker='✕'
        state_text='失败'
        color="$XMJ_WARN"
        ;;
      success)
        marker='✓'
        state_text='已完成'
        color="$XMJ_CREAM"
        ;;
      *)
        marker='➜'
        state_text='进行中'
        color="$XMJ_PINK"
        ;;
    esac
  fi

  printf '  %b%s%b %b%s%b %b·%b %b%s%b\n' \
    "$color" "$marker" "$XMJ_RESET" \
    "$XMJ_WHITE" "$(xmj_launch_stage_label "$stage")" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$color" "$state_text" "$XMJ_RESET"
}

xmj_render_launch_tavern_state() {
  if [ -z "${XMJ_LAUNCH_TAVERN_VERSION:-}" ] \
    && [ -z "${XMJ_LAUNCH_TAVERN_BRANCH:-}" ] \
    && [ -z "${XMJ_LAUNCH_TAVERN_COMMIT:-}" ]; then
    return 0
  fi

  printf '\n'

  if [ -n "${XMJ_LAUNCH_TAVERN_VERSION:-}" ]; then
    xmj_render_fact_line '酒馆版本' "${XMJ_LAUNCH_TAVERN_VERSION}"
  fi

  if [ -n "${XMJ_LAUNCH_TAVERN_BRANCH:-}" ]; then
    xmj_render_fact_line '酒馆分支' "${XMJ_LAUNCH_TAVERN_BRANCH}"
  fi

  if [ -n "${XMJ_LAUNCH_TAVERN_COMMIT:-}" ]; then
    xmj_render_fact_line '当前提交' "${XMJ_LAUNCH_TAVERN_COMMIT}"
  fi
}

xmj_render_launch_progress() {
  local current_stage="${1:-prepare}"
  local headline="${2:-准备启动}"
  local detail_text="${3:-₍˄·͈༝·͈˄₎◞ 猫猫正在安静整理启动步骤喵~}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro \
    '₍ᐢ..ᐢ₎♡ 启动酒馆进行中喵~ 前台不会直接刷出 Node / npm 输出。' \
    '详细内容会悄悄写进日志本，只保留简洁状态页。'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" '按 Ctrl+C 可以结束这次启动的酒馆，然后回到首页喵~'
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' "$current_stage" 'running'
  xmj_render_launch_stage_line 'env' "$current_stage" 'running'
  xmj_render_launch_stage_line 'boot' "$current_stage" 'running'
  xmj_render_launch_stage_line 'running' "$current_stage" 'running'
  xmj_render_launch_tavern_state

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_launch_running_screen() {
  local entry_url="${XMJ_LAUNCH_ENTRY_URL:-}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro \
    '₍ᐢ..ᐢ₎♡ 酒馆已经进入运行中喵~ 下面会实时展示后台日志输出。' \
    '按 Ctrl+C 会结束这次启动的酒馆，并回到首页。'
  printf '\n'
  xmj_render_setting_card \
    '运行中' \
    '现在可以直接进入酒馆，也可以继续看下面的实时日志。' \
    '日志会持续追加，方便直接检查报错。'
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' 'running' 'running'
  xmj_render_launch_stage_line 'env' 'running' 'running'
  xmj_render_launch_stage_line 'boot' 'running' 'running'
  xmj_render_launch_stage_line 'running' 'running' 'running'
  xmj_render_launch_tavern_state

  printf '\n'
  if [ -n "$entry_url" ]; then
    xmj_render_fact_line '进入链接' "$entry_url"
  fi

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  if [ -n "${XMJ_LAUNCH_PID:-}" ]; then
    xmj_render_fact_line 'PID' "${XMJ_LAUNCH_PID}"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  printf '  %b♡ 实时日志%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '  %b以下开始持续追加后台输出，方便直接看报错。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
}

xmj_render_launch_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-running}"
  local summary_text="${3:-酒馆已经开始运行喵~}"
  local detail_text="${4:-}"
  local result_title='运行状态'
  local result_intro='₍˄·͈༝·͈˄₎◞ 猫猫已经把状态整理好了喵~'
  local result_hint=''
  local stage_mode='success'
  local auto_back='0'

  case "$result_mode" in
    failure)
      result_title='启动失败'
      result_intro='₍ᐢ..ᐢ₎♡ 这次启动没有顺利完成喵~'
      result_hint='需要时可温和查看日志本。'
      stage_mode='failure'
      ;;
    stopped)
      result_title='已停止运行'
      result_intro='₍˄·͈༝·͈˄₎◞ 已收到 Ctrl+C，猫猫正在把酒馆收起来喵~'
      result_hint='马上就会回到首页。'
      stage_mode='success'
      auto_back='1'
      ;;
    exited)
      result_title='运行已结束'
      result_intro='₍ᐢ..ᐢ₎♡ 酒馆已经结束本次运行喵~'
      result_hint='需要时可温和查看日志本。'
      stage_mode='success'
      ;;
    *)
      result_title='运行状态'
      result_intro='₍˄·͈༝·͈˄₎◞ 猫猫已经把状态整理好了喵~'
      result_hint=''
      stage_mode='success'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro "$result_intro" "$result_hint"
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'boot' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'running' "$current_stage" "$stage_mode"
  xmj_render_launch_tavern_state

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  if [ "$auto_back" = '1' ]; then
    printf '\n'
    xmj_rule_line "$XMJ_BORDER" '─' 68
    printf '  %b马上回到首页喵~%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
    return 0
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_backend_display_screen() {
  local mode="${1:-running}"
  local primary_text='这里只实时显示当前酒馆后台输出。'
  local secondary_text='按 Ctrl+C 会结束这次运行的酒馆，并回到首页。'
  local card_title='实时后台'
  local card_detail='当前已经接到最新的 launch 后台日志，会持续刷新输出。'
  local card_note='这个页面不提供其他操作。'

  case "$mode" in
    empty)
      primary_text='还没有可显示的酒馆后台。'
      secondary_text='先跑一次 01 启动酒馆，生成 launch 日志后再来看。'
      card_title='暂无后台'
      card_detail='当前日志目录里还没有 launch 后台日志。'
      card_note='这个页面不提供其他操作。'
      ;;
    stopped)
      primary_text='当前没有正在运行的酒馆，这里展示最近一次后台记录。'
      secondary_text='这个页面不提供其他操作，按回车返回首页。'
      card_title='最近后台'
      card_detail='下面是最新一份 launch 后台日志的尾部内容。'
      card_note='如果要继续启动新的酒馆，请回到 01。'
      ;;
    *)
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['06']}" 'backend display' 'setting'
  printf '\n'
  xmj_render_page_intro "$primary_text" "$secondary_text"
  printf '\n'
  xmj_render_setting_card "$card_title" "$card_detail" "$card_note"
  printf '\n'

  if [ -n "${XMJ_LAUNCH_ENTRY_URL:-}" ]; then
    xmj_render_fact_line '进入链接' "${XMJ_LAUNCH_ENTRY_URL}"
  fi

  if [ -n "${XMJ_LAUNCH_PID:-}" ]; then
    xmj_render_fact_line 'PID' "${XMJ_LAUNCH_PID}"
  fi

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "${XMJ_LAUNCH_LOG_FILE}")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  printf '  %b♡ 酒馆后台%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'
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

xmj_render_page_title() {
  local title="${1:-}"
  local phrase="${2:-preview page}"
  local section="${3:-update}"
  local decor="${XMJ_SECTION_DECOR[$section]}"

  printf '%b%s%b %b%s%b %b--%b %b%s%b %b. *%b\n' \
    "$XMJ_PINK" "$decor" "$XMJ_RESET" \
    "$XMJ_BLUE_SOFT" "$phrase" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$XMJ_WHITE" "$title" "$XMJ_RESET" \
    "$XMJ_LAVENDER" "$XMJ_RESET"
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
  printf '\n'
  xmj_render_menu_row '19' '20'
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
  local hint='  请输入编号，1 和 01 都可以，00 退出。'

  panel_width="$(xmj_panel_width)"
  if [ "$panel_width" -lt 30 ]; then
    hint='  编号 / 00退出'
  elif [ "$panel_width" -lt 42 ]; then
    hint='  输入编号，1 / 01 都可以。'
  fi

  printf '%b%s%b\n' "$XMJ_BLUE" "$hint" "$XMJ_RESET"
}

xmj_render_home() {
  local section

  xmj_clear_screen
  xmj_render_header
  printf '\n'

  for section in "${XMJ_SECTION_ORDER[@]}"; do
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

  printf '  %b说明%b：%b目前 01 - 14 的更新、备份与依赖环境功能都已接入真实流程；06 现在改成直接关闭酒馆，并会补跑 pkill node 兜底。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_MIST" "$XMJ_RESET"
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
  xmj_render_page_identity '23' "${XMJ_MENU_LABEL['23']}"
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
  xmj_render_path_block '自动备份目录' \
    "$(xmj_display_path "$(xmj_maintenance_backup_dir)")" \
    "$(xmj_dir_state "$(xmj_maintenance_backup_dir)" '已就绪' '待创建')"
  xmj_render_page_footer '按回车返回首页'
}

xmj_setting_view_title() {
  local view="${1:-home}"

  case "$view" in
    font)
      printf '%s' '字体管理'
      ;;
    autostart)
      printf '%s' '是否自启动'
      ;;
    script_update)
      printf '%s' '脚本更新'
      ;;
    script_branch)
      printf '%s' '脚本分支'
      ;;
    script_version)
      printf '%s' '脚本版本'
      ;;
    logs)
      printf '%s' '后台显示'
      ;;
    logs_keep_count)
      printf '%s' '日志保留数量'
      ;;
    logs_delete_confirm)
      printf '%s' '删除日志确认'
      ;;
    logs_cleanup_confirm)
      printf '%s' '清理日志确认'
      ;;
    *)
      printf '%s' '设置中心'
      ;;
  esac
}

xmj_setting_view_id() {
  local view="${1:-home}"

  case "$view" in
    font)
      printf '%s' '19-1'
      ;;
    autostart)
      printf '%s' '19-2'
      ;;
    script_update)
      printf '%s' '19-3'
      ;;
    script_branch)
      printf '%s' '19-4'
      ;;
    script_version)
      printf '%s' '19-5'
      ;;
    logs)
      printf '%s' '19-6'
      ;;
    logs_keep_count)
      printf '%s' '19-6-1'
      ;;
    logs_delete_confirm)
      printf '%s' '19-6-2'
      ;;
    logs_cleanup_confirm)
      printf '%s' '19-6-3'
      ;;
    *)
      printf '%s' '19'
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
  xmj_render_fact_line '当前主题' "$(xmj_theme_label)"
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '配置状态' "$(xmj_config_status_text)"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  printf '\n'
  xmj_render_setting_card '1 · 基础设置' '' '脚本信息 / 路径'
  printf '\n'
  xmj_render_setting_card '2 · 主题 / 外观' '' "当前：$(xmj_theme_label)"
  printf '\n'
  xmj_render_setting_card '3 · 字体管理' '' "当前：$(xmj_termux_font_status_text)"
  printf '\n'
  xmj_render_setting_card '4 · 高级项预留' '' '功能预留'
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
  xmj_render_path_block '自动备份目录' \
    "$(xmj_display_path "$(xmj_maintenance_backup_dir)")" \
    "$(xmj_dir_state "$(xmj_maintenance_backup_dir)" '已就绪' '待创建')"
  printf '\n'
  xmj_render_page_intro '修改配置请编辑 config/xiaomaojuan.conf。' ''
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
  xmj_render_fact_line '当前主题' "$(xmj_theme_label)"
  xmj_render_fact_line '主题字段' "${XMJ_THEME_MODE:-pastel}"
  xmj_render_fact_line '边框风格' '软糖感分隔线 / 浅色渐柔边框'
  xmj_render_fact_line '标题状态' '保持当前主标题装饰'
  printf '\n'
  xmj_render_setting_card 'pastel · 粉蓝白系' '' '默认主题'
  printf '\n'
  xmj_render_setting_card 'moonlight · 月光蓝紫系' '' '可通过 XMJ_THEME_MODE 切换'
  printf '\n'
  xmj_render_page_intro '切换主题请编辑 config/xiaomaojuan.conf。' ''
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
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '字体路径' "$(xmj_display_path "$font_file")"
  xmj_render_fact_line '备份状态' "$backup_state"
  xmj_render_fact_line '内置预设' "${XMJ_TERMUX_FONT_PRESET_NAME:-未设置}"
  xmj_render_fact_line '下载来源' "$(xmj_termux_font_source_host)"
  xmj_render_fact_line '资源格式' "$preset_format"
  printf '\n'
  xmj_render_page_intro '字体操作会影响整个 Termux。' '自定义预设请编辑 config/xiaomaojuan.conf。'
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
  xmj_render_page_intro '功能预留，后续完善。' ''
  printf '\n'
  xmj_render_fact_line '功能状态' '占位中'
  xmj_render_fact_line '当前定位' '仅保留结构'
  xmj_render_notice_line
  xmj_render_action_footer '输入 0 返回设置中心。'
}

xmj_render_tavern_setting_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'setting'
  printf '\n'
  xmj_render_page_identity '20' "${XMJ_MENU_LABEL['20']}"
  printf '\n'
  xmj_render_page_intro '功能预留，后续完善。' ''
  printf '\n'
  xmj_render_fact_line '页面状态' '占位页'
  xmj_render_fact_line '业务逻辑' '暂未接入'
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_setting_center_page() {
  local view="${1:-home}"

  case "$view" in
    font)
      xmj_render_setting_font_page
      ;;
    autostart)
      xmj_render_setting_autostart_page
      ;;
    script_update)
      xmj_render_setting_script_update_page
      ;;
    script_branch)
      xmj_render_setting_script_branch_page
      ;;
    script_version)
      xmj_render_setting_script_version_page
      ;;
    logs)
      xmj_render_setting_logs_page
      ;;
    logs_keep_count)
      xmj_render_setting_logs_keep_count_page
      ;;
    logs_delete_confirm)
      xmj_render_setting_logs_delete_confirm_page
      ;;
    logs_cleanup_confirm)
      xmj_render_setting_logs_cleanup_confirm_page
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
  xmj_render_page_identity '24' "${XMJ_MENU_LABEL['24']}"
  printf '\n'
  xmj_render_page_intro \
    '小猫卷目前是一个运行在 Termux 里的 Bash 面板框架。' \
    '首页仍以功能分组为主，其中 01 - 14 的更新、备份与依赖环境功能已经接入真实逻辑。'
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
  xmj_render_page_identity '25' "${XMJ_MENU_LABEL['25']}"
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
    '当前版本主要用于确认配置、面板结构和已接入的更新流程。' \
    '目前已实现 01 - 14 的更新、备份、恢复与依赖环境流程，扩展脚本分组仍在整理中。'
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_menu_page() {
  local id="${1:-}"

  case "$id" in
    20)
      xmj_render_tavern_setting_page
      ;;
    23)
      xmj_render_about_status_page
      ;;
    24)
      xmj_render_about_panel_page
      ;;
    25)
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
    '当前页面仍是温柔占位页，不会执行额外业务操作。'
  printf '\n'
  xmj_render_fact_line '所属分组' "${XMJ_SECTION_TITLE[$section]}"
  xmj_render_fact_line '功能状态' '预留中'
  printf '\n'
  xmj_render_page_intro \
    '你现在看到的是视觉占位页，后续会在这里补上对应业务逻辑。' \
    '目前 01 - 14 已接入真实流程，其余入口仍在整理。'
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_invalid_input() {
  local input="${1:-}"

  printf '\n'
  printf '  %b输入无效%b：%b%s%b\n' "$XMJ_WARN" "$XMJ_RESET" "$XMJ_PINK" "$input" "$XMJ_RESET"
  printf '  %b仅支持输入 00 - 25 的菜单编号。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  xmj_wait_for_enter '按回车返回首页'
}
# Slimmed page variants: keep the visual style, drop page intros and file paths.
xmj_render_update_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理更新步骤。}"
  local stage_for_display='prepare'

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'install update' 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_update_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-当前已经是最新版本。}"
  local detail_text="${4:-}"
  local before_commit="${6:-}"
  local after_commit="${7:-}"
  local result_title='更新完成'
  local stage_mode='success'
  local stage_for_display='done'

  if [ "$result_mode" = 'failure' ]; then
    result_title='更新失败'
    stage_mode='failure'
  fi

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'install update' 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"

  if [ "$result_mode" = 'success' ] \
    && [ -n "$before_commit" ] \
    && [ -n "$after_commit" ] \
    && [ "$before_commit" != "$after_commit" ]; then
    printf '  %b版本变化%b：%b%s -> %s%b\n' \
      "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$before_commit" "$after_commit" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_reinstall_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理卸载重装步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['04']}" 'reinstall tavern' 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 卸载重装进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_reinstall_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'remove' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'install' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'done' "$current_stage" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_reinstall_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-卸载重装已完成。}"
  local detail_text="${4:-}"
  local result_title='卸载重装完成'
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='卸载重装失败'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['04']}" 'reinstall tavern' 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 卸载重装进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_reinstall_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'remove' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'install' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'done' "$current_stage" "$stage_mode"

  if [ -n "${XMJ_REINSTALL_AFTER_VERSION:-}" ]; then
    printf '\n'
    xmj_render_fact_line '当前版本' "${XMJ_REINSTALL_AFTER_VERSION}"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_launch_progress() {
  local current_stage="${1:-prepare}"
  local headline="${2:-准备启动}"
  local detail_text="${3:-猫猫正在安静整理启动步骤喵~}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['01']}" 'launch tavern' 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" '按 Ctrl+C 可以结束这次启动的酒馆，然后回到首页喵'
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' "$current_stage" 'running'
  xmj_render_launch_stage_line 'env' "$current_stage" 'running'
  xmj_render_launch_stage_line 'boot' "$current_stage" 'running'
  xmj_render_launch_stage_line 'running' "$current_stage" 'running'
  xmj_render_launch_tavern_state

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ] || [ -n "${XMJ_LAUNCH_RUNTIME_FILE:-}" ]; then
    xmj_launch_render_boot_log_snapshot '18'
  fi
}

xmj_render_launch_running_screen() {
  local entry_url="${XMJ_LAUNCH_ENTRY_URL:-}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['01']}" 'launch tavern' 'update'
  printf '\n'
  xmj_render_setting_card \
    '运行中' \
    '已经等到 SillyTavern is listening on 这行后切进运行页，下面会先保留启动尾部，再继续显示运行期后台输出。' \
    '按 Ctrl+C 会结束这次启动的酒馆，并回到首页。'
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' 'running' 'running'
  xmj_render_launch_stage_line 'env' 'running' 'running'
  xmj_render_launch_stage_line 'boot' 'running' 'running'
  xmj_render_launch_stage_line 'running' 'running' 'running'
  xmj_render_launch_tavern_state

  printf '\n'
  if [ -n "$entry_url" ]; then
    xmj_render_fact_line '进入链接' "$entry_url"
  fi

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  if [ -n "${XMJ_LAUNCH_PID:-}" ]; then
    xmj_render_fact_line 'PID' "${XMJ_LAUNCH_PID}"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 酒馆后台%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'
}

xmj_render_launch_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-running}"
  local summary_text="${3:-酒馆已经开始运行喵~}"
  local detail_text="${4:-}"
  local result_title='运行状态'
  local stage_mode='success'
  local auto_back='0'

  case "$result_mode" in
    failure)
      result_title='启动失败'
      stage_mode='failure'
      ;;
    stopped)
      result_title='已停止运行'
      stage_mode='success'
      auto_back='1'
      ;;
    exited)
      result_title='运行已结束'
      stage_mode='success'
      ;;
    *)
      result_title='运行状态'
      stage_mode='success'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['01']}" 'launch tavern' 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 启动小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_launch_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'boot' "$current_stage" "$stage_mode"
  xmj_render_launch_stage_line 'running' "$current_stage" "$stage_mode"
  xmj_render_launch_tavern_state

  if [ -n "${XMJ_LAUNCH_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_LAUNCH_LOG_FILE")"
  fi

  if [ "$auto_back" = '1' ]; then
    printf '\n'
    xmj_rule_line "$XMJ_BORDER" '鈹€' 68
    printf '  %b马上回到首页喵%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
    return 0
  fi

  if [ "$result_mode" = 'failure' ] || [ "$result_mode" = 'exited' ]; then
    printf '\n'
    xmj_rule_line "$XMJ_BORDER" '鈹€' 68
    printf '  %b♡ 最近日志%b\n' "$XMJ_PINK" "$XMJ_RESET"
    printf '  %b下面直接展示最近输出，方便马上看报错。%b\n' "$XMJ_MIST" "$XMJ_RESET"
    printf '\n'
    xmj_launch_render_log_snapshot '18'
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_startup_notice() {
  if [ "${XMJ_BOOT_NOTICE_SHOWN:-0}" = '1' ]; then
    return 0
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '启动摘要' 'startup brief' 'info'
  printf '\n'

  if [ "${#XMJ_BOOT_MESSAGES[@]}" -gt 0 ] || [ "${#XMJ_BOOT_WARNINGS[@]}" -gt 0 ]; then
    printf '  %b猫猫把开场小纸条叠好啦，你看一眼就能进首页。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
  fi

  if [ "${#XMJ_BOOT_MESSAGES[@]}" -gt 0 ]; then
    printf '  %b猫猫刚刚顺手做好的事%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
    xmj_render_boot_lines "$XMJ_WHITE" "${XMJ_BOOT_MESSAGES[@]}"
    printf '\n'
  fi

  if [ "${#XMJ_BOOT_WARNINGS[@]}" -gt 0 ]; then
    printf '  %b猫猫想轻轻提醒你%b\n' "$XMJ_WARN" "$XMJ_RESET"
    xmj_render_boot_lines "$XMJ_CREAM" "${XMJ_BOOT_WARNINGS[@]}"
    printf '\n'
  fi

  if [ "${#XMJ_BOOT_MESSAGES[@]}" -eq 0 ] && [ "${#XMJ_BOOT_WARNINGS[@]}" -eq 0 ]; then
    printf '  %b猫猫已经把开场收拾好了，直接进首页就行喵。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
  fi

  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  XMJ_BOOT_NOTICE_SHOWN=1
  xmj_wait_for_enter '按回车让猫猫带你进首页'
}

xmj_render_startup_failure() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '启动失败' 'startup failure' 'info'
  printf '\n'
  printf '  %b猫猫这次没把开场整理好，先看看下面这些喵。%b\n' "$XMJ_WARN" "$XMJ_RESET"
  printf '\n'

  if [ "${#XMJ_BOOT_ERRORS[@]}" -gt 0 ]; then
    xmj_render_boot_lines "$XMJ_WARN" "${XMJ_BOOT_ERRORS[@]}"
  else
    printf '  %b• 这次没拿到具体报错，先查脚本权限和配置语法喵。%b\n' "$XMJ_WARN" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  xmj_wait_for_enter '按回车先结束这次启动'
}

xmj_render_about_status_page() {
  xmj_setting_refresh_script_repo_state >/dev/null 2>&1 || true

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['23']}" 'runtime status' 'about'
  printf '\n'
  printf '  %b这里专门收纳小猫卷自己的版本信息。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前版本' "$(xmj_setting_script_current_version_text)"
  xmj_render_fact_line '更新日志' "$(xmj_setting_script_current_changelog_text)"
  xmj_render_fact_line '当前分支' "${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_page_footer '按回车回首页'
}

xmj_render_setting_overview_page() {
  xmj_setting_refresh_script_repo_state

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['19']}" 'settings hub' 'setting'
  printf '\n'
  printf '  %b想调哪里就点哪里，猫猫把说明都压短啦。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  xmj_render_setting_card '1 · 字体管理' '' "当前：$(xmj_termux_font_status_text)"
  printf '\n'
  xmj_render_setting_card '2 · 是否自启动' '' "当前：$(xmj_setting_autostart_status_text)"
  printf '\n'
  xmj_render_setting_card '3 · 脚本更新' '' "当前：$(xmj_setting_script_current_version_text)"
  printf '\n'
  xmj_render_setting_card '4 · 脚本分支' '' "当前：${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  printf '\n'
  xmj_render_setting_card '5 · 脚本版本' '' "提交：${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '进入字体管理'
  xmj_render_action_item '2' '查看是否自启动'
  xmj_render_action_item '3' '检查脚本更新'
  xmj_render_action_item '4' '切换脚本分支'
  xmj_render_action_item '5' '查看脚本版本'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 5 / 0 就好喵'
}

xmj_render_setting_font_page() {
  local backup_file
  local backup_state='未生成'

  backup_file="$(xmj_termux_font_backup_file)"
  if [ -f "$backup_file" ]; then
    backup_state='已存在'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'font')" 'font manager' 'setting'
  printf '\n'
  printf '  %b字体这边猫猫也帮你收得很短啦。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前字体' "$(xmj_termux_font_status_text)"
  xmj_render_fact_line '备份状态' "$backup_state"
  xmj_render_fact_line '内置预设' "${XMJ_TERMUX_FONT_PRESET_NAME:-未设置}"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' "安装内置字体：${XMJ_TERMUX_FONT_PRESET_NAME:-未设置}"
  xmj_render_action_item '2' '恢复默认字体'
  xmj_render_action_item '3' '重新加载 Termux 设置'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入 1 / 2 / 3 / 0 就好喵'
}

xmj_render_setting_autostart_page() {
  local shell_file=''
  local legacy_script=''
  local legacy_state='未发现'

  shell_file="$(xmj_setting_autostart_shell_file)"
  legacy_script="$(xmj_setting_autostart_legacy_script_file)"
  if [ -f "$legacy_script" ]; then
    legacy_state='已发现'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'autostart')" 'auto start' 'setting'
  printf '\n'
  printf '  %b这里管的是打开 Termux 后自动运行小猫卷脚本。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b不是设备开机自启，也不再依赖 Termux:Boot。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前状态' "$(xmj_setting_autostart_status_text)"
  xmj_render_fact_line '启动配置' "$(xmj_display_path "$shell_file")"
  xmj_render_fact_line '启动方式' '打开 Termux 时自动执行'
  xmj_render_fact_line '启动目标' '打开 Termux 后自动执行 xiaomaojuan.sh'
  xmj_render_fact_line '旧版开机自启残留' "$legacy_state"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '开启打开 Termux 自启动'
  xmj_render_action_item '2' '关闭打开 Termux 自启动'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入 1 / 2 / 0 就好喵'
}

xmj_render_setting_script_update_page() {
  local action_label=''
  local action_hint='输入 0 返回设置中心'

  xmj_setting_refresh_script_update_status >/dev/null 2>&1 || true

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'script_update')" 'script update' 'setting'
  printf '\n'
  printf '  %b这里会先检查当前分支是不是最新版本。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b如果已经是最新版本，就不用继续更新；只有检测到远端新版本时，才由你自己决定要不要更新。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前版本' "$(xmj_setting_script_current_version_text)"
  xmj_render_fact_line '当前更新日志' "$(xmj_setting_script_current_changelog_text)"
  xmj_render_fact_line '当前分支' "${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_fact_line '检查结果' "${XMJ_SETTING_SCRIPT_UPDATE_STATUS_TEXT:-还没检查远端版本}"
  xmj_render_fact_line '远端分支' "${XMJ_SETTING_SCRIPT_UPDATE_REMOTE_BRANCH:-未识别}"

  if [ -n "${XMJ_SETTING_SCRIPT_UPDATE_REMOTE_COMMIT:-}" ]; then
    xmj_render_fact_line '远端版本' "${XMJ_SETTING_SCRIPT_UPDATE_REMOTE_VERSION:-未识别}"
    xmj_render_fact_line '远端更新日志' "${XMJ_SETTING_SCRIPT_UPDATE_REMOTE_NOTE:-暂无}"
  fi

  xmj_render_fact_line '上游分支' "${XMJ_SETTING_SCRIPT_UPSTREAM:-未配置}"
  xmj_render_fact_line '工作区' "$(xmj_setting_script_worktree_text)"

  if [ -n "${XMJ_SETTING_SCRIPT_UPDATE_LOG:-}" ]; then
    xmj_render_fact_line '执行日志' "$(xmj_display_path "$XMJ_SETTING_SCRIPT_UPDATE_LOG")"
  fi

  xmj_render_notice_line
  printf '\n'

  case "${XMJ_SETTING_SCRIPT_UPDATE_STATE:-unknown}" in
    behind)
      action_label='更新到远端最新版本'
      action_hint='输入 1 开始更新 / 0 返回设置中心'
      ;;
    check_failed)
      action_label='仍然尝试更新'
      action_hint='输入 1 继续尝试更新 / 0 返回设置中心'
      ;;
    latest)
      action_hint='当前已经是最新版本，输入 0 返回设置中心'
      ;;
    ahead)
      action_hint='当前本地版本领先远端，输入 0 返回设置中心'
      ;;
    diverged)
      action_hint='当前分支和远端已分叉，先处理分支后再回来；输入 0 返回设置中心'
      ;;
    *)
      action_hint='当前暂时不能直接更新，输入 0 返回设置中心'
      ;;
  esac

  if [ -n "$action_label" ]; then
    xmj_render_action_item '1' "$action_label"
  fi
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer "$action_hint"
}

xmj_render_setting_script_branch_page() {
  xmj_setting_refresh_script_repo_state

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'script_branch')" 'script branch' 'setting'
  printf '\n'
  printf '  %b这里切的是小猫卷脚本自己的 Git 分支，不是酒馆分支。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b切完会自动重开脚本，避免界面还停在旧代码上。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前分支' "${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_fact_line '脚本版本' "${XMJ_SETTING_SCRIPT_VERSION:-未识别}"
  xmj_render_fact_line '上游分支' "${XMJ_SETTING_SCRIPT_UPSTREAM:-未配置}"
  xmj_render_fact_line '工作区' "$(xmj_setting_script_worktree_text)"
  xmj_render_fact_line '远程仓库' "${XMJ_SETTING_SCRIPT_REMOTE:-未配置}"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '切到 main'
  xmj_render_action_item '2' '切到 test'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入 1 / 2 / 0 就好喵'
}

xmj_render_setting_script_version_page() {
  xmj_setting_refresh_script_repo_state

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'script_version')" 'script version' 'setting'
  printf '\n'
  printf '  %b这里主要拿来看小猫卷自己现在是哪一版。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '脚本版本' "${XMJ_SETTING_SCRIPT_VERSION:-未识别}"
  xmj_render_fact_line '当前分支' "${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_fact_line '精确标签' "${XMJ_SETTING_SCRIPT_TAG:-未命中}"
  xmj_render_fact_line '版本描述' "${XMJ_SETTING_SCRIPT_DESCRIBE:-未识别}"
  xmj_render_fact_line '仓库状态' "$(xmj_setting_script_worktree_text)"
  xmj_render_fact_line '远程仓库' "${XMJ_SETTING_SCRIPT_REMOTE:-未配置}"
  xmj_render_fact_line '脚本目录' "$(xmj_display_path "${XMJ_ROOT_DIR:-.}")"
  xmj_render_notice_line
  xmj_render_action_footer '输入 0 回设置中心'
}

xmj_render_setting_logs_page() {
  local display_count='0'
  local selected_file=''
  local selected_name=''
  local total_lines='0'
  local index='0'

  xmj_setting_refresh_log_files
  display_count="$(xmj_setting_log_display_count)"
  selected_file="$(xmj_setting_selected_log_file)"

  if [ -n "$selected_file" ]; then
    selected_name="$(basename "$selected_file")"
    total_lines="$(xmj_setting_log_line_count "$selected_file")"
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'logs')" 'log viewer' 'setting'
  printf '  %b01 进入运行中后，运行期后台只会在当前页面实时直显；06 现在改成关闭酒馆，不再承担后台查看。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '  %b这里现在只看 launch 启动日志和最近记录，点序号就能看尾部预览。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b更新日志和脚本更新日志不会在这里出现；这里只看启动期与最近后台记录。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '  %b删单个和按保留数量清理也只处理后台日志，不会碰更新日志。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '日志目录' "$(xmj_display_path "${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}")"
  xmj_render_fact_line '后台数量' "${#XMJ_SETTING_LOG_FILES[@]}"
  xmj_render_fact_line '保留策略' "保留最新 $(xmj_setting_log_keep_count) 份"

  if [ "$display_count" -gt 0 ]; then
    xmj_render_fact_line '当前查看' "$selected_name"
    xmj_render_fact_line '总行数' "$total_lines"
    printf '\n'
    xmj_render_setting_card '最新后台' '' "这里只展示最新 ${display_count} 份。"
    printf '\n'

    for ((index = 0; index < display_count; index += 1)); do
      xmj_render_action_item "$((index + 1))" "$(basename "${XMJ_SETTING_LOG_FILES[$index]}")"
    done

    printf '\n'
    xmj_rule_line "$XMJ_BORDER" '─' 68
    printf '  %b♡ 尾部预览%b\n' "$XMJ_PINK" "$XMJ_RESET"
    printf '\n'
    xmj_setting_print_log_tail "$selected_file" '18'
  else
    xmj_render_setting_card '还没有后台喵' '先跑一次 01 启动酒馆，生成 launch 日志后，这里就会有内容。' ''
  fi

  xmj_render_notice_line
  printf '\n'
  if [ "$display_count" -gt 0 ]; then
    xmj_render_action_item 'd' '删除当前后台日志'
    xmj_render_action_item 'a' '按保留数量清理旧后台'
  fi
  xmj_render_action_item 'k' '修改后台保留数量'
  xmj_render_action_item 'r' '刷新后台列表'
  xmj_render_action_item '0' '返回设置中心'
  if [ "$display_count" -gt 0 ]; then
    xmj_render_action_footer '输入后台序号 / d / a / k / r / 0 就好喵'
  else
    xmj_render_action_footer '输入 k / r / 0 就好喵'
  fi
}

xmj_render_setting_logs_keep_count_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'logs_keep_count')" 'log viewer' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里改的是后台页自动清理时要保留的数量' \
    '输入新的正整数后，会直接写进 xiaomaojuan.conf。' \
    '改完不会立刻删后台；要真正清理旧后台，回后台页按 a 再执行一次。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_setting_view_id 'logs_keep_count')"
  xmj_render_fact_line '当前数量' "$(xmj_setting_log_keep_count)"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成新的后台保留数量'
  xmj_render_action_item '0' '返回后台显示'
  xmj_render_action_footer '输入新的保留数量 / 0 返回后台显示'
}

xmj_render_setting_logs_delete_confirm_page() {
  local target_file="${XMJ_SETTING_LOG_DELETE_TARGET:-}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'logs_delete_confirm')" 'log viewer' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这次会删掉当前选中的那一份后台日志' \
    "${target_file##*/}" \
    '删除后不会自动恢复。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_setting_view_id 'logs_delete_confirm')"
  xmj_render_fact_line '目标文件' "$(xmj_display_path "$target_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item 'y' '确认删除这份后台日志'
  xmj_render_action_item '0' '取消并返回后台显示'
  xmj_render_action_footer '输入 y / 0 就好喵'
}

xmj_render_setting_logs_cleanup_confirm_page() {
  local keep_count=''

  keep_count="$(xmj_setting_log_keep_count)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'logs_cleanup_confirm')" 'log viewer' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这次会按当前保留策略整理旧后台日志' \
    "只保留最新 ${keep_count} 份后台日志。" \
    '更旧的后台日志会被直接删除，删除后不会自动恢复。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_setting_view_id 'logs_cleanup_confirm')"
  xmj_render_fact_line '日志目录' "$(xmj_display_path "${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}")"
  xmj_render_fact_line '当前策略' "保留最新 ${keep_count} 份"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item 'y' '确认执行这次清理'
  xmj_render_action_item '0' '取消并返回后台显示'
  xmj_render_action_footer '输入 y / 0 就好喵'
}

xmj_render_tavern_setting_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['20']}" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里先收短啦' \
    '酒馆设置这页先不常驻跨版本提醒。' \
    '真要切版本且会影响设置时，猫猫会在 03 版本切换里单独拎出来确认。'
  xmj_render_page_footer '按回车回首页'
}

xmj_render_about_panel_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['24']}" 'about panel' 'about'
  printf '\n'
  xmj_render_setting_card '小猫卷面板' '一只负责把常用动作收整齐的小面板。' "当前主题：$(xmj_theme_label)"
  xmj_render_page_footer '按回车回首页'
}

xmj_render_author_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['25']}" 'author info' 'about'
  printf '\n'
  xmj_render_setting_card '作者' "${XMJ_SCRIPT_AUTHOR:-meoroll}" '猫猫在这里轻轻留个名'
  xmj_render_page_footer '按回车回首页'
}

xmj_render_placeholder_page() {
  local id="${1:-}"
  local title="${XMJ_MENU_LABEL[$id]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$title" 'coming soon' "${XMJ_MENU_SECTION[$id]}"
  printf '\n'
  xmj_render_setting_card '这里先空着喵' '猫猫还没把这页补完，之后再慢慢长内容。' ''
  xmj_render_page_footer '按回车回首页'
}

xmj_render_compat_notice_card() {
  local mode="${1:-switch}"
  local summary_text=''

  case "$mode" in
    update)
      summary_text="如果当前版本低于 $(xmj_maintenance_compat_floor_version)（不包含 $(xmj_maintenance_compat_floor_version) 本身），猫猫这次只会备份 / 恢复 data。"
      ;;
    *)
      summary_text="如果当前版本或要切过去的版本低于 $(xmj_maintenance_compat_floor_version)（不包含 $(xmj_maintenance_compat_floor_version) 本身），猫猫这次只会备份 / 恢复 data。"
      ;;
  esac

  xmj_render_setting_card \
    '低版本兼容提醒' \
    "$summary_text" \
    '多用户插件可能要重装，酒馆设置也要重新改。'
}

xmj_render_update_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理更新步骤。}"
  local stage_for_display='prepare'

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'install update' 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"
  printf '\n'
  xmj_render_compat_notice_card 'update'
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '·' 68
}

xmj_render_update_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-当前已经是最新版本。}"
  local detail_text="${4:-}"
  local before_commit="${6:-}"
  local after_commit="${7:-}"
  local result_title='更新完成'
  local stage_mode='success'
  local stage_for_display='done'

  if [ "$result_mode" = 'failure' ]; then
    result_title='更新失败'
    stage_mode='failure'
  fi

  stage_for_display="$(xmj_update_display_stage "$current_stage")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'install update' 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"

  if [ "$result_mode" = 'success' ] \
    && [ -n "$before_commit" ] \
    && [ -n "$after_commit" ] \
    && [ "$before_commit" != "$after_commit" ]; then
    printf '  %b版本变化%b：%b%s -> %s%b\n' \
      "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$before_commit" "$after_commit" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b♡ 更新小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_update_stage_line 'prepare' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'env' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'backup' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'local' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'pull' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'deps' "$stage_for_display" "$stage_mode"
  xmj_render_update_stage_line 'recover' "$stage_for_display" "$stage_mode"

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" = '1' ] \
    || [ "$stage_for_display" = 'restore' ] \
    || [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ]; then
    xmj_render_update_stage_line 'restore' "$stage_for_display" "$stage_mode"
  fi

  xmj_render_update_stage_line 'done' "$stage_for_display" "$stage_mode"
  printf '\n'
  xmj_render_compat_notice_card 'update'
  xmj_render_page_footer '按回车返回首页'
}

xmj_render_tavern_setting_page() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      xmj_render_tavern_setting_browser_redirect_page
      ;;
    avatar_hd)
      xmj_render_tavern_setting_avatar_hd_page
      ;;
    stutter_fix)
      xmj_render_tavern_setting_stutter_fix_page
      ;;
    stutter_fix_user)
      xmj_render_tavern_setting_stutter_fix_user_page
      ;;
    file_chat_limit)
      xmj_render_tavern_setting_file_chat_limit_page
      ;;
    memory_limit)
      xmj_render_tavern_setting_memory_limit_page
      ;;
    port_conflict)
      xmj_render_tavern_setting_port_conflict_page
      ;;
    security_guard)
      xmj_render_tavern_setting_security_guard_page
      ;;
    multi_user_login)
      xmj_render_tavern_setting_multi_user_login_page
      ;;
    chat_freeze_fix)
      xmj_render_tavern_setting_chat_freeze_fix_page
      ;;
    beautify_freeze_fix)
      xmj_render_tavern_setting_beautify_freeze_fix_page
      ;;
    backup_keep_count)
      xmj_render_tavern_setting_backup_keep_count_page
      ;;
    *)
      xmj_render_tavern_setting_overview_page
      ;;
  esac
}

xmj_tavern_setting_view_title() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      printf '%s' '浏览器跳转'
      ;;
    avatar_hd)
      printf '%s' '头像高清'
      ;;
    stutter_fix)
      printf '%s' '卡顿修复'
      ;;
    file_chat_limit)
      printf '%s' '文件聊天上限修改'
      ;;
    memory_limit)
      printf '%s' '运行内存修改'
      ;;
    port_conflict)
      printf '%s' '修复端口冲突'
      ;;
    security_guard)
      printf '%s' '安全修复'
      ;;
    multi_user_login)
      printf '%s' '多用户登录'
      ;;
    chat_freeze_fix)
      printf '%s' '聊天加载卡死修复'
      ;;
    beautify_freeze_fix)
      printf '%s' '美化卡死修复'
      ;;
    backup_keep_count)
      printf '%s' '修改备份数量'
      ;;
    *)
      printf '%s' "${XMJ_MENU_LABEL['20']}"
      ;;
  esac
}

xmj_tavern_setting_view_id() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      printf '%s' '20-1'
      ;;
    avatar_hd)
      printf '%s' '20-2'
      ;;
    stutter_fix)
      printf '%s' '20-3'
      ;;
    file_chat_limit)
      printf '%s' '20-4'
      ;;
    memory_limit)
      printf '%s' '20-5'
      ;;
    port_conflict)
      printf '%s' '20-6'
      ;;
    security_guard)
      printf '%s' '20-10'
      ;;
    multi_user_login)
      printf '%s' '20-11'
      ;;
    chat_freeze_fix)
      printf '%s' '20-7'
      ;;
    beautify_freeze_fix)
      printf '%s' '20-8'
      ;;
    backup_keep_count)
      printf '%s' '20-9'
      ;;
    *)
      printf '%s' '20'
      ;;
  esac
}

xmj_tavern_setting_status_text() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      xmj_tavern_setting_browser_redirect_status_text
      ;;
    avatar_hd)
      xmj_tavern_setting_avatar_hd_status_text
      ;;
    stutter_fix)
      xmj_tavern_setting_stutter_fix_status_text
      ;;
    file_chat_limit)
      xmj_tavern_setting_file_chat_limit_status_text
      ;;
    memory_limit)
      xmj_tavern_setting_memory_limit_status_text
      ;;
    port_conflict)
      xmj_tavern_setting_port_conflict_status_text
      ;;
    security_guard)
      xmj_tavern_setting_security_guard_status_text
      ;;
    multi_user_login)
      xmj_tavern_setting_multi_user_login_status_text
      ;;
    chat_freeze_fix)
      xmj_tavern_setting_chat_freeze_fix_status_text
      ;;
    beautify_freeze_fix)
      xmj_tavern_setting_beautify_freeze_fix_status_text
      ;;
    backup_keep_count)
      printf '当前：保留最新 %s 个' "$(xmj_backup_cleanup_keep_count)"
      ;;
    *)
      printf '%s' '当前：等你继续给规则'
      ;;
  esac
}

xmj_render_tavern_setting_overview_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['20']}" 'tavern setting' 'setting'
  printf '\n'
  printf '  %b酒馆设置现在一共收这 11 项，猫猫按你给的名字排好了。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b真要切版本且会影响设置时，确认提示还是会放在 03 版本切换里单独弹。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_setting_card '1 · 浏览器跳转' '' "$(xmj_tavern_setting_status_text 'browser_redirect')"
  printf '\n'
  xmj_render_setting_card '2 · 头像高清' '' "$(xmj_tavern_setting_status_text 'avatar_hd')"
  printf '\n'
  xmj_render_setting_card '3 · 卡顿修复' '' "$(xmj_tavern_setting_status_text 'stutter_fix')"
  printf '\n'
  xmj_render_setting_card '4 · 文件聊天上限修改' '' "$(xmj_tavern_setting_status_text 'file_chat_limit')"
  printf '\n'
  xmj_render_setting_card '5 · 运行内存修改' '' "$(xmj_tavern_setting_status_text 'memory_limit')"
  printf '\n'
  xmj_render_setting_card '6 · 修复端口冲突' '' "$(xmj_tavern_setting_status_text 'port_conflict')"
  printf '\n'
  xmj_render_setting_card '7 · 聊天加载卡死修复' '' "$(xmj_tavern_setting_status_text 'chat_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '8 · 美化卡死修复' '' "$(xmj_tavern_setting_status_text 'beautify_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '9 · 修改备份数量' '' "$(xmj_tavern_setting_status_text 'backup_keep_count')"
  printf '\n'
  xmj_render_setting_card '10 · 安全修复' '' "$(xmj_tavern_setting_status_text 'security_guard')"
  printf '\n'
  xmj_render_setting_card '11 · 多用户登录' '' "$(xmj_tavern_setting_status_text 'multi_user_login')"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '浏览器跳转'
  xmj_render_action_item '2' '头像高清'
  xmj_render_action_item '3' '卡顿修复'
  xmj_render_action_item '4' '文件聊天上限修改'
  xmj_render_action_item '5' '运行内存修改'
  xmj_render_action_item '6' '修复端口冲突'
  xmj_render_action_item '7' '聊天加载卡死修复'
  xmj_render_action_item '8' '美化卡死修复'
  xmj_render_action_item '9' '修改备份数量'
  xmj_render_action_item '10' '安全修复'
  xmj_render_action_item '11' '多用户登录'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 / 11 / 0 就好喵'
}

xmj_render_tavern_setting_browser_redirect_page() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'browser_redirect')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项可以开关浏览器自动跳转' \
    '猫猫会去酒馆配置文件里找到 browserLaunch 这一段，按你的选择把 enabled 改成 true 或 false。' \
    '改完后重开酒馆，就会按新的开关状态决定要不要自动弹去系统浏览器。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'browser_redirect')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'browser_redirect')"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '开启浏览器跳转'
  xmj_render_action_item '2' '关闭浏览器跳转'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 开启 / 2 关闭 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_avatar_hd_page() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'avatar_hd')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会把头像切回原图显示' \
    '猫猫会去酒馆配置文件里找到 thumbnails 这一段，把 enabled 改成 false。' \
    '这样酒馆就不会再优先走缩略头像，Echo / Whisper 之类模式下也更容易保持清晰。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'avatar_hd')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'avatar_hd')"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_stutter_fix_page() {
  local config_file=''
  local user_name=''
  local settings_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'stutter_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会一起改两处卡顿相关设置' \
    '第 1 步会把 config.yaml 里的 lazyLoadCharacters 改成 true；第 2 步会把对应用户 settings.json 里的 auto_load_chat 改成 false。' \
    '如果你没开多用户，用户名通常就是 default-user。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'stutter_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'stutter_fix')"
  xmj_render_fact_line '当前用户名' "$user_name"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '2' '修改用户名'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 2 改用户名 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_stutter_fix_user_page() {
  local current_user=''
  local default_user=''

  current_user="$(xmj_tavern_setting_user_name)"
  default_user="$(xmj_tavern_setting_default_user_name)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '修改用户名' 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里填的是酒馆 data 目录下的用户名文件夹' \
    '猫猫会按这个名字去找对应的 settings.json。' \
    "如果没有开启多用户，直接用 ${default_user} 就好。"
  printf '\n'
  xmj_render_fact_line '当前用户名' "$current_user"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '直接输入用户名' '输入后会保存并回到上一页'
  xmj_render_action_item '0' '返回卡顿修复'
  xmj_render_action_footer '直接输入用户名 / 0 返回卡顿修复'
}

xmj_render_tavern_setting_file_chat_limit_page() {
  local config_file=''
  local target=''
  local scope=''
  local section=''
  local key=''
  local unit_hint=''
  local current_value=''
  local resolved_unit=''
  local matched_key='当前版本没匹配到'

  config_file="$(xmj_tavern_setting_config_file)"
  target="$(xmj_tavern_setting_file_chat_limit_target)"

  if [ -n "$target" ]; then
    IFS='|' read -r scope config_file section key unit_hint current_value <<EOF
$target
EOF
    resolved_unit="$(xmj_tavern_setting_size_unit_from_hint "$unit_hint" "$current_value")"
    matched_key="$(xmj_tavern_setting_file_chat_limit_key_label "$scope" "$section" "$key") = $(xmj_tavern_setting_size_display_text "$current_value" "$resolved_unit")"
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'file_chat_limit')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会去改酒馆当前版本真的在用的文件聊天上限键' \
    '不同版本键名不完全一样，所以猫猫会先在当前 config.yaml 里找已经存在的那一项，再只改那一项。' \
    '这里输入的是 MB 数字；如果那一项配置本身记的是 bytes，猫猫会自动帮你换算。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'file_chat_limit')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'file_chat_limit')"
  xmj_render_fact_line '匹配到的键' "$matched_key"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成新的文件聊天上限（按 MB 输入）'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入新的上限数字 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_memory_limit_page() {
  local memory_limit_mb="${XMJ_TAVERN_NODE_MEMORY_MB:-0}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'memory_limit')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项改的是小猫卷启动酒馆时附加的 Node 内存上限' \
    '猫猫会把数值写进 xiaomaojuan.conf 里的 XMJ_TAVERN_NODE_MEMORY_MB，01 启动酒馆时自动拼进 NODE_OPTIONS。' \
    '直接输入新的 MB 数值就行；输入 0 恢复默认启动内存，回车可以直接返回酒馆设置。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'memory_limit')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'memory_limit')"
  xmj_render_fact_line '当前数值' "${memory_limit_mb} MB"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成新的内存上限（MB）'
  xmj_render_action_item '0' '恢复默认启动内存'
  xmj_render_action_item '回车' '返回酒馆设置'
  xmj_render_action_footer '输入新的 MB 数值 / 0 恢复默认 / 回车返回酒馆设置'
}

xmj_render_tavern_setting_port_conflict_page() {
  local config_file=''
  local tavern_port=''
  local script_port="${XMJ_TAVERN_PORT:-8000}"

  config_file="$(xmj_tavern_setting_config_file)"
  tavern_port="$(xmj_tavern_setting_yaml_top_value "$config_file" 'port')"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'port_conflict')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会一起同步酒馆监听端口和小猫卷访问端口' \
    '第 1 步会把酒馆 config.yaml 顶层的 port 改掉；第 2 步会把小猫卷自己的 XMJ_TAVERN_PORT 也同步成一样。' \
    '直接输入新的端口数字就行；改完后重开酒馆，小猫卷就会按新的端口检测和进入。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'port_conflict')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'port_conflict')"
  xmj_render_fact_line '酒馆配置端口' "${tavern_port:-未读取到}"
  xmj_render_fact_line '面板访问端口' "$script_port"
  xmj_render_fact_line '酒馆配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '面板配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '端口数字' '直接改成新的端口'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入新的端口数字 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_placeholder_detail_page() {
  local view="${1:-home}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title "$view")" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '入口已经留好啦' \
    '这一项已经单独放进酒馆设置里了。' \
    '你后面继续把具体规则告诉猫猫，猫猫再把它接成真正可用的修改动作。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id "$view")"
  xmj_render_fact_line '当前状态' '暂时还是占位页'
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 0 返回酒馆设置'
}

xmj_render_tavern_setting_stutter_fix_user_page() {
  local current_user=''
  local default_user=''

  current_user="$(xmj_tavern_setting_user_name)"
  default_user="$(xmj_tavern_setting_default_user_name)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '修改用户名' 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里填的是酒馆 data 目录下的用户名文件夹' \
    '猫猫会按这个名字去找对应的 settings.json。' \
    "如果没有开多用户，直接用 ${default_user} 就好。"
  printf '\n'
  xmj_render_fact_line '当前用户名' "$current_user"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '直接输入用户名' '输入后会保存并回到上一级'
  xmj_render_action_item '0' '返回上一级'
  xmj_render_action_footer '直接输入用户名 / 0 返回上一级'
}

xmj_render_tavern_setting_file_chat_limit_page() {
  local server_main_file=''
  local body_parser_limit=''

  server_main_file="$(xmj_tavern_setting_server_main_file)"
  body_parser_limit="$(xmj_tavern_setting_body_parser_limit_text "$server_main_file")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'file_chat_limit')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项改的是 SillyTavern 服务端请求体上限，不是 config.yaml' \
    '聊天记录保存会走 /api/chats/save，所以真正卡住 .jsonl 上传或保存的，通常是 server-main.js 里的 bodyParser.json 和 bodyParser.urlencoded。' \
    '这里输入的是 MB 数字；猫猫会把同一份代码文件里的 json / urlencoded 上传限制一起补到你给的值。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'file_chat_limit')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'file_chat_limit')"
  xmj_render_fact_line 'bodyParser limit' "$body_parser_limit"
  xmj_render_fact_line '代码文件' "$(xmj_display_path "${server_main_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成新的文件聊天上限（按 MB 输入）'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入新的上限数字 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_memory_limit_page() {
  local memory_limit_mb="${XMJ_TAVERN_NODE_MEMORY_MB:-0}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'memory_limit')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项改的是小猫卷启动酒馆时附加的 Node 内存上限' \
    '猫猫会把数值写进 xiaomaojuan.conf 里的 XMJ_TAVERN_NODE_MEMORY_MB，01 启动酒馆时自动拼进 NODE_OPTIONS；这一项不直接去魔改 ST 核心源码。' \
    '常用值可以先试 2048 / 4096 / 6144 / 8192；输入 0 恢复默认启动内存，回车可以直接返回酒馆设置。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'memory_limit')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'memory_limit')"
  xmj_render_fact_line '当前数值' "${memory_limit_mb} MB"
  xmj_render_fact_line '推荐起点' '2048 / 4096 / 6144 / 8192 MB'
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成新的内存上限（MB）'
  xmj_render_action_item '0' '恢复默认启动内存'
  xmj_render_action_item '回车' '返回酒馆设置'
  xmj_render_action_footer '输入新的 MB 数字 / 0 恢复默认 / 回车返回酒馆设置'
}

xmj_render_tavern_setting_port_conflict_page() {
  local config_file=''
  local tavern_port=''
  local script_port="${XMJ_TAVERN_PORT:-8000}"
  local recommended_port=''

  config_file="$(xmj_tavern_setting_config_file)"
  tavern_port="$(xmj_tavern_setting_yaml_top_value "$config_file" 'port')"
  recommended_port="$(xmj_tavern_setting_random_safe_port)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'port_conflict')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会一起同步酒馆监听端口和小猫卷访问端口' \
    '第 1 步会把酒馆 config.yaml 顶层的 port 改掉；第 2 步会把小猫卷自己的 XMJ_TAVERN_PORT 也同步成一样。' \
    '推荐优先用 10000 到 49151 的普通端口；像 8000 / 8080 / 8888 这些常见端口容易撞车，猫猫会直接拦下来。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'port_conflict')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'port_conflict')"
  xmj_render_fact_line '酒馆配置端口' "${tavern_port:-未读到}"
  xmj_render_fact_line '面板访问端口' "$script_port"
  xmj_render_fact_line '推荐范围' '10000 - 49151'
  xmj_render_fact_line '建议端口' "$recommended_port"
  xmj_render_fact_line '酒馆配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '面板配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '端口数字' '直接改成新的端口'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入新的端口数字 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_security_guard_page() {
  local config_file=''
  local current_version=''
  local compat_floor=''

  config_file="$(xmj_tavern_setting_config_file)"
  current_version="$(xmj_tavern_setting_current_version)"
  compat_floor="$(xmj_maintenance_compat_floor_version)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'security_guard')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会把 hostWhitelist 改成只允许本机访问' \
    "主要面向 ${compat_floor} 及以上版本；猫猫会把 hostWhitelist 写成 enabled: true、scan: true，并只保留 localhost / 127.0.0.1 / [::1]。" \
    '如果你平时只在本机或本机浏览器里玩，这样更稳；但局域网和外网访问会一起被拦住，改完后要重开酒馆。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'security_guard')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'security_guard')"
  xmj_render_fact_line '当前版本' "${current_version:-未读到}"
  xmj_render_fact_line '建议版本' "${compat_floor} 及以上"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_multi_user_login_page() {
  local config_file=''
  local enable_accounts=''
  local discreet_login=''

  config_file="$(xmj_tavern_setting_config_file)"
  enable_accounts="$(xmj_tavern_setting_yaml_top_value "$config_file" 'enableUserAccounts')"
  discreet_login="$(xmj_tavern_setting_yaml_top_value "$config_file" 'enableDiscreetLogin')"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'multi_user_login')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会开启多用户，并让你选择登录页样式' \
    '方案 1 是头像列表版：登录页先展示头像和用户名，点头像后再输入密码；方案 2 是账号密码版：直接输入账号和密码。' \
    '猫猫会改 config.yaml 里的 enableUserAccounts 和 enableDiscreetLogin；改完后重开酒馆生效。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'multi_user_login')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'multi_user_login')"
  xmj_render_fact_line 'enableUserAccounts' "${enable_accounts:-未写入}"
  xmj_render_fact_line 'enableDiscreetLogin' "${discreet_login:-未写入}"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '切到头像列表登录页'
  xmj_render_action_item '2' '切到账号密码登录页'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 切头像列表 / 2 切账号密码 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_chat_freeze_fix_page() {
  local config_file=''
  local user_name=''
  local settings_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'chat_freeze_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项专门处理一进酒馆就被聊天自动加载卡住的情况' \
    '猫猫会把当前用户 settings.json 里的 auto_load_chat 改成 false，再把 config.yaml 里的 lazyLoadCharacters 改成 true。' \
    '这样下次重开酒馆时，不会再一进来就强行把上一次聊天拖起来；有问题的聊天可以等你进得去之后再手动处理。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'chat_freeze_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'chat_freeze_fix')"
  xmj_render_fact_line '当前用户名' "$user_name"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '2' '修改用户名'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 2 改用户名 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_beautify_freeze_fix_page() {
  local user_name=''
  local settings_file=''
  local theme_value=''
  local custom_css=''

  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"
  theme_value="$(xmj_tavern_setting_json_string_value "$settings_file" 'theme')"
  custom_css="$(xmj_tavern_setting_json_string_value "$settings_file" 'custom_css')"
  if [ -z "$custom_css" ]; then
    custom_css="$(xmj_tavern_setting_json_string_value "$settings_file" 'customCss')"
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'beautify_freeze_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项专门处理主题或自定义 CSS 把酒馆界面卡死的情况' \
    '猫猫会把当前用户 settings.json 里的 theme 改回 Dark Lite，并把 custom_css 清空。' \
    '如果是某个主题包、残留美化或者一段坏掉的自定义 CSS 让你连设置页都点不进去，这一项就是在酒馆外面把它们先撤掉。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'beautify_freeze_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'beautify_freeze_fix')"
  xmj_render_fact_line '当前用户名' "$user_name"
  xmj_render_fact_line '当前主题' "${theme_value:-未读到}"
  xmj_render_fact_line 'custom_css' "${custom_css:+有内容}${custom_css:-空的}"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '切回安全主题'
  xmj_render_action_item '2' '修改用户名'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 2 改用户名 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_backup_keep_count_page() {
  local keep_count=''

  keep_count="$(xmj_backup_cleanup_keep_count)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'backup_keep_count')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里改的是自动清理备份的留存数量' \
    '影响的是 10 清理旧档 里的自动清理动作。' \
    '输入新的正整数就会直接写进配置文件；比如输入 3，就表示只保留最新 3 个备份。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'backup_keep_count')"
  xmj_render_fact_line '当前数量' "$keep_count"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '正整数' '直接改成对应的保留数量'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入新的保留数量 / 0 返回酒馆设置'
}

xmj_render_script_password_page() {
  return 0

  local mode="${1:-first_open}"
  local title='安装密码'
  local summary='首次打开小猫卷前，要先过一下安装密码。'

  case "$mode" in
    script_update)
      title='脚本更新验证'
      summary='更新小猫卷脚本前，要先输入安装密码。'
      ;;
    script_branch)
      title='脚本分支切换验证'
      summary='切换小猫卷脚本分支前，要先输入安装密码。'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$title" 'password check' 'setting'
  printf '\n'
  xmj_render_setting_card \
    "$title" \
    "$summary" \
    '提示：本喵的名字。'
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '直接输入密码' '输入正确就继续'
  xmj_render_action_item '0' '取消这次操作'
  xmj_render_action_footer '直接输入密码 / 0 取消'
}
