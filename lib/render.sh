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
    '一键更新进行中，详细命令会悄悄写进日志本。' \
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
  local result_intro='猫猫已经把一键更新整理好了。'
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

  printf '  %b说明%b：%b目前 01 - 14 的更新、备份与依赖环境功能都已接入真实流程，教程说明与扩展脚本入口仍保留占位结构。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_MIST" "$XMJ_RESET"
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
    script_version)
      printf '%s' '脚本版本'
      ;;
    logs)
      printf '%s' '日志查看'
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
    script_version)
      printf '%s' '19-4'
      ;;
    logs)
      printf '%s' '19-5'
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
    script_version)
      xmj_render_setting_script_version_page
      ;;
    logs)
      xmj_render_setting_logs_page
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
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'one-click update' 'update'
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
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'one-click update' 'update'
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
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_launch_running_screen() {
  local entry_url="${XMJ_LAUNCH_ENTRY_URL:-}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['01']}" 'launch tavern' 'update'
  printf '\n'
  xmj_render_setting_card \
    '运行中' \
    '现在可以直接进入酒馆，也可以继续看下面的实时日志。' \
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

  if [ -n "${XMJ_LAUNCH_PID:-}" ]; then
    xmj_render_fact_line 'PID' "${XMJ_LAUNCH_PID}"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 实时日志%b\n' "$XMJ_PINK" "$XMJ_RESET"
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

  if [ "$auto_back" = '1' ]; then
    printf '\n'
    xmj_rule_line "$XMJ_BORDER" '鈹€' 68
    printf '  %b马上回到首页喵%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
    return 0
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
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['23']}" 'runtime status' 'about'
  printf '\n'
  printf '  %b猫猫现在的状态都叠在这里啦。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '配置' "$(xmj_config_status_text)"
  xmj_render_fact_line '酒馆' "$(xmj_dir_state "${XMJ_SILLYTAVERN_PATH:-}" '已发现' '待确认')"
  xmj_render_fact_line '备份' "$(xmj_dir_state "$(xmj_maintenance_backup_dir)" '已就绪' '待创建')"
  xmj_render_page_footer '按回车回首页'
}

xmj_render_setting_overview_page() {
  local log_count='0'

  xmj_setting_refresh_script_repo_state
  xmj_setting_refresh_log_files
  log_count="${#XMJ_SETTING_LOG_FILES[@]}"

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
  xmj_render_setting_card '3 · 脚本更新' '' "当前：${XMJ_SETTING_SCRIPT_VERSION:-未识别}"
  printf '\n'
  xmj_render_setting_card '4 · 脚本版本' '' "分支：${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  printf '\n'
  xmj_render_setting_card '5 · 日志查看' '' "当前：${log_count} 份日志"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '进入字体管理'
  xmj_render_action_item '2' '查看是否自启动'
  xmj_render_action_item '3' '检查脚本更新'
  xmj_render_action_item '4' '查看脚本版本'
  xmj_render_action_item '5' '查看日志'
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
  xmj_setting_refresh_script_repo_state

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_setting_view_title 'script_update')" 'script update' 'setting'
  printf '\n'
  printf '  %b这里会在小猫卷仓库里执行 git pull --ff-only。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b更完之后，重新打开小猫卷才会吃到新代码。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_SETTING_SCRIPT_VERSION:-未识别}"
  xmj_render_fact_line '当前分支' "${XMJ_SETTING_SCRIPT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  xmj_render_fact_line '上游分支' "${XMJ_SETTING_SCRIPT_UPSTREAM:-未配置}"
  xmj_render_fact_line '工作区' "$(xmj_setting_script_worktree_text)"

  if [ -n "${XMJ_SETTING_SCRIPT_UPDATE_LOG:-}" ]; then
    xmj_render_fact_line '更新日志' "$(xmj_display_path "$XMJ_SETTING_SCRIPT_UPDATE_LOG")"
  fi

  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即检查并更新脚本'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入 1 / 0 就好喵'
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
  printf '\n'
  printf '  %b这里先摆最新日志，点序号就能看尾部预览。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b详细内容还是留在原日志文件里。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_fact_line '日志目录' "$(xmj_display_path "${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}")"
  xmj_render_fact_line '日志数量' "${#XMJ_SETTING_LOG_FILES[@]}"

  if [ "$display_count" -gt 0 ]; then
    xmj_render_fact_line '当前查看' "$selected_name"
    xmj_render_fact_line '总行数' "$total_lines"
    printf '\n'
    xmj_render_setting_card '最新日志' '' "这里只展示最新 ${display_count} 份。"
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
    xmj_render_setting_card '还没有日志喵' '等你跑过启动、更新、版本切换这些动作后，这里就会有内容。' ''
  fi

  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item 'r' '刷新日志列表'
  xmj_render_action_item '0' '返回设置中心'
  xmj_render_action_footer '输入日志序号 / r / 0 就好喵'
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
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'one-click update' 'update'
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
  xmj_render_page_title "${XMJ_MENU_LABEL['02']}" 'one-click update' 'update'
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
    file_chat_limit|memory_limit|port_conflict|chat_freeze_fix|beautify_freeze_fix)
      xmj_render_tavern_setting_placeholder_detail_page "$view"
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
  printf '  %b酒馆设置一共先收这 9 项，猫猫按你给的名字排好了。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
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
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 0 就好喵'
}

xmj_render_tavern_setting_browser_redirect_page() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'browser_redirect')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会关掉浏览器自动跳转' \
    '猫猫会去酒馆配置文件里找到 browserLaunch 这一段，把 enabled 改成 false。' \
    '改完后重开酒馆，就不会再自己弹去系统浏览器。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'browser_redirect')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'browser_redirect')"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
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
  local mode="${1:-first_open}"
  local title='安装密码'
  local summary='首次打开小猫卷前，要先过一下安装密码。'

  case "$mode" in
    script_update)
      title='脚本更新验证'
      summary='更新小猫卷脚本前，要先输入安装密码。'
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
