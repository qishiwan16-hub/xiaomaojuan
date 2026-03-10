xmj_launch_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown-time'
  fi

  printf '%s' "$timestamp"
}

xmj_launch_reset_state() {
  XMJ_LAUNCH_LOG_FILE=''
  XMJ_LAUNCH_LOG_CURSOR='0'
  XMJ_LAUNCH_STAGE='prepare'
  XMJ_LAUNCH_SUMMARY=''
  XMJ_LAUNCH_DETAIL=''
  XMJ_LAUNCH_METHOD=''
  XMJ_LAUNCH_METHOD_TEXT=''
  XMJ_LAUNCH_COMMAND=''
  XMJ_LAUNCH_ENTRY_FILE=''
  XMJ_LAUNCH_ENTRY_URL=''
  XMJ_LAUNCH_PID=''
  XMJ_LAUNCH_EXIT_CODE=''
  XMJ_LAUNCH_TAVERN_VERSION=''
  XMJ_LAUNCH_TAVERN_BRANCH=''
  XMJ_LAUNCH_TAVERN_COMMIT=''
  XMJ_LAUNCH_TAVERN_TAG=''
  XMJ_LAUNCH_TAVERN_DESCRIBE=''
  XMJ_LAUNCH_INTERRUPT='0'
  XMJ_LAUNCH_WAITED='0'
  XMJ_LAUNCH_USE_PGID='0'
  XMJ_LAUNCH_PREVIOUS_INT_TRAP=''
}

xmj_launch_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_LAUNCH_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_launch_timestamp)" "$line" >>"$XMJ_LAUNCH_LOG_FILE"
}

xmj_launch_prepare_log_file() {
  local stamp=''

  if [ -z "${XMJ_LOG_DIR:-}" ]; then
    XMJ_LOG_DIR="${XMJ_ROOT_DIR:-.}/logs"
  fi

  if ! mkdir -p "$XMJ_LOG_DIR" 2>/dev/null; then
    return 1
  fi

  stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stamp" ]; then
    stamp='manual'
  fi

  XMJ_LAUNCH_LOG_FILE="$XMJ_LOG_DIR/launch-$stamp.log"
  if ! : >"$XMJ_LAUNCH_LOG_FILE" 2>/dev/null; then
    return 1
  fi

  xmj_launch_log_line '小猫卷启动日志已创建。'
  xmj_launch_log_line "目标目录：${XMJ_SILLYTAVERN_PATH:-未设置}"
  return 0
}

xmj_launch_fail() {
  local stage="${1:-env}"
  local summary="${2:-启动失败}"
  local detail="${3:-请温和查看日志。}"

  XMJ_LAUNCH_STAGE="$stage"
  XMJ_LAUNCH_SUMMARY="$summary"
  XMJ_LAUNCH_DETAIL="$detail"

  xmj_launch_log_line "失败阶段：$stage"
  xmj_launch_log_line "失败摘要：$summary"
  xmj_launch_log_line "失败说明：$detail"
  return 1
}

xmj_launch_access_host() {
  local host="${XMJ_TAVERN_HOST:-127.0.0.1}"

  case "$host" in
    ''|0.0.0.0|::|'[::]')
      printf '%s' '127.0.0.1'
      ;;
    *)
      printf '%s' "$host"
      ;;
  esac
}

xmj_launch_entry_url() {
  local host=''
  local port="${XMJ_TAVERN_PORT:-8000}"
  local path="${XMJ_TAVERN_ENTRY_PATH:-/}"

  host="$(xmj_launch_access_host)"

  case "$host" in
    \[*\])
      ;;
    *:*)
      host="[$host]"
      ;;
  esac

  printf 'http://%s:%s%s' "$host" "$port" "$path"
}

xmj_launch_can_probe_url() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

xmj_launch_endpoint_available() {
  local url="${1:-}"

  if [ -z "$url" ]; then
    return 1
  fi

  if command -v curl >/dev/null 2>&1; then
    curl -sS --connect-timeout 2 --max-time 3 -o /dev/null "$url" >/dev/null 2>&1
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -T 3 -O /dev/null "$url" >/dev/null 2>&1
    return $?
  fi

  return 1
}

xmj_launch_update_tavern_state() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local repo_flag=''
  local branch_name=''
  local describe_name=''
  local exact_tag=''
  local commit_name=''

  XMJ_LAUNCH_TAVERN_VERSION=''
  XMJ_LAUNCH_TAVERN_BRANCH=''
  XMJ_LAUNCH_TAVERN_COMMIT=''
  XMJ_LAUNCH_TAVERN_TAG=''
  XMJ_LAUNCH_TAVERN_DESCRIBE=''

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    xmj_launch_log_line '未检测到 Git，启动页将跳过酒馆版本信息。'
    return 0
  fi

  repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$XMJ_LAUNCH_LOG_FILE" || true)"
  if [ "$repo_flag" != 'true' ]; then
    xmj_launch_log_line '当前目录不是 Git 仓库，启动页将跳过酒馆版本信息。'
    return 0
  fi

  commit_name="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_LAUNCH_LOG_FILE" || true)"
  branch_name="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_LAUNCH_LOG_FILE" || true)"
  describe_name="$(git -C "$repo_path" describe --tags --always --dirty 2>>"$XMJ_LAUNCH_LOG_FILE" || true)"
  exact_tag="$(git -C "$repo_path" describe --tags --exact-match 2>>"$XMJ_LAUNCH_LOG_FILE" || true)"

  XMJ_LAUNCH_TAVERN_COMMIT="${commit_name:-unknown}"
  XMJ_LAUNCH_TAVERN_TAG="$exact_tag"
  XMJ_LAUNCH_TAVERN_DESCRIBE="$describe_name"

  if [ -n "$exact_tag" ]; then
    XMJ_LAUNCH_TAVERN_VERSION="$exact_tag"
  elif [ -n "$describe_name" ]; then
    XMJ_LAUNCH_TAVERN_VERSION="$describe_name"
  elif [ -n "$commit_name" ]; then
    XMJ_LAUNCH_TAVERN_VERSION="$commit_name"
  else
    XMJ_LAUNCH_TAVERN_VERSION='未知'
  fi

  if [ -n "$branch_name" ]; then
    XMJ_LAUNCH_TAVERN_BRANCH="$branch_name"
  else
    XMJ_LAUNCH_TAVERN_BRANCH='detached'
  fi

  xmj_launch_log_line "酒馆版本：${XMJ_LAUNCH_TAVERN_VERSION}"
  xmj_launch_log_line "酒馆分支：${XMJ_LAUNCH_TAVERN_BRANCH}"
  xmj_launch_log_line "当前提交：${XMJ_LAUNCH_TAVERN_COMMIT}"
  return 0
}

xmj_launch_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ -z "$repo_path" ]; then
    xmj_launch_fail 'env' '未设置酒馆路径' '请先在配置里填写 SillyTavern 目录。'
    return 1
  fi

  if [ ! -d "$repo_path" ]; then
    xmj_launch_fail 'env' '未找到酒馆目录' '请先确认配置里的 SillyTavern 目录是否正确。'
    return 1
  fi

  xmj_launch_update_tavern_state
  xmj_launch_log_line '酒馆目录检查通过。'
  return 0
}

xmj_launch_detect_command() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local package_json=''

  package_json="$repo_path/package.json"

  if [ -f "$repo_path/start.sh" ]; then
    XMJ_LAUNCH_METHOD='start_sh'
    XMJ_LAUNCH_METHOD_TEXT='bash ./start.sh'
    XMJ_LAUNCH_COMMAND='bash ./start.sh'
    XMJ_LAUNCH_ENTRY_FILE='start.sh'
    xmj_launch_log_line '检测到 start.sh，准备使用 bash ./start.sh 启动喵~'
    return 0
  fi

  if [ -f "$package_json" ] && grep -Eq '"start"[[:space:]]*:' "$package_json" 2>/dev/null; then
    if ! command -v npm >/dev/null 2>&1; then
      xmj_launch_fail 'env' '未检测到 npm' '检测到 package.json 的 start 脚本，但当前环境无法执行 npm。'
      return 1
    fi

    XMJ_LAUNCH_METHOD='npm_start'
    XMJ_LAUNCH_METHOD_TEXT='npm run start'
    XMJ_LAUNCH_COMMAND='npm run start'
    XMJ_LAUNCH_ENTRY_FILE='package.json'
    xmj_launch_log_line '检测到 package.json 的 start 脚本，准备使用 npm run start 启动喵~'
    return 0
  fi

  if [ -f "$repo_path/server.js" ]; then
    if ! command -v node >/dev/null 2>&1; then
      xmj_launch_fail 'env' '未检测到 Node.js' '检测到 server.js，但当前环境无法执行 node。'
      return 1
    fi

    XMJ_LAUNCH_METHOD='node_server'
    XMJ_LAUNCH_METHOD_TEXT='node ./server.js'
    XMJ_LAUNCH_COMMAND='node ./server.js'
    XMJ_LAUNCH_ENTRY_FILE='server.js'
    xmj_launch_log_line '检测到 server.js，准备使用 node ./server.js 启动喵~'
    return 0
  fi

  xmj_launch_fail 'env' '未识别到可用启动入口' '未找到 start.sh、package.json 的 start 脚本或 server.js。'
  return 1
}

xmj_launch_capture_int_trap() {
  XMJ_LAUNCH_PREVIOUS_INT_TRAP="$(trap -p INT 2>/dev/null || true)"
}

xmj_launch_install_int_trap() {
  XMJ_LAUNCH_INTERRUPT='0'
  xmj_launch_capture_int_trap
  trap 'XMJ_LAUNCH_INTERRUPT=1' INT
}

xmj_launch_restore_int_trap() {
  if [ -n "${XMJ_LAUNCH_PREVIOUS_INT_TRAP:-}" ]; then
    eval "$XMJ_LAUNCH_PREVIOUS_INT_TRAP"
  else
    trap - INT
  fi
}

xmj_launch_process_alive() {
  local pid="${XMJ_LAUNCH_PID:-}"

  if [ -z "$pid" ]; then
    return 1
  fi

  kill -0 "$pid" 2>/dev/null
}

xmj_launch_wait_process() {
  local pid="${XMJ_LAUNCH_PID:-}"
  local exit_code='0'

  if [ -n "${XMJ_LAUNCH_WAITED:-}" ] && [ "$XMJ_LAUNCH_WAITED" = '1' ]; then
    printf '%s' "${XMJ_LAUNCH_EXIT_CODE:-0}"
    return 0
  fi

  if [ -z "$pid" ]; then
    XMJ_LAUNCH_EXIT_CODE='0'
    XMJ_LAUNCH_WAITED='1'
    printf '%s' '0'
    return 0
  fi

  wait "$pid" 2>/dev/null
  exit_code=$?
  XMJ_LAUNCH_EXIT_CODE="$exit_code"
  XMJ_LAUNCH_WAITED='1'
  printf '%s' "$exit_code"
}

xmj_launch_start_process() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ -z "${XMJ_LAUNCH_COMMAND:-}" ]; then
    xmj_launch_fail 'boot' '缺少启动命令' '当前还没有识别出可用的酒馆启动方式。'
    return 1
  fi

  XMJ_LAUNCH_WAITED='0'
  XMJ_LAUNCH_EXIT_CODE=''
  XMJ_LAUNCH_USE_PGID='0'

  if command -v setsid >/dev/null 2>&1; then
    (
      cd "$repo_path" || exit 1
      exec setsid bash -lc "exec ${XMJ_LAUNCH_COMMAND}" </dev/null
    ) >>"$XMJ_LAUNCH_LOG_FILE" 2>&1 &
    XMJ_LAUNCH_USE_PGID='1'
    xmj_launch_log_line '已使用 setsid 创建独立进程组。'
  else
    (
      cd "$repo_path" || exit 1
      exec bash -lc "exec ${XMJ_LAUNCH_COMMAND}" </dev/null
    ) >>"$XMJ_LAUNCH_LOG_FILE" 2>&1 &
    xmj_launch_log_line '当前环境未检测到 setsid，已退回普通后台启动。'
  fi

  XMJ_LAUNCH_PID="$!"
  if [ -z "$XMJ_LAUNCH_PID" ]; then
    xmj_launch_fail 'boot' '启动失败' '没有成功拿到后台进程信息。'
    return 1
  fi

  xmj_launch_log_line "启动方式：${XMJ_LAUNCH_METHOD_TEXT:-unknown}"
  xmj_launch_log_line "启动命令：${XMJ_LAUNCH_COMMAND}"
  xmj_launch_log_line "启动入口：${XMJ_LAUNCH_ENTRY_FILE:-unknown}"
  xmj_launch_log_line "后台进程 PID：${XMJ_LAUNCH_PID}"
  return 0
}

xmj_launch_send_signal() {
  local signal="${1:-TERM}"
  local pid="${XMJ_LAUNCH_PID:-}"
  local signal_sent='0'

  if [ -z "$pid" ]; then
    return 1
  fi

  if [ "${XMJ_LAUNCH_USE_PGID:-0}" = '1' ]; then
    if kill "-$signal" -- "-$pid" 2>/dev/null; then
      signal_sent='1'
    fi
  fi

  if kill "-$signal" "$pid" 2>/dev/null; then
    signal_sent='1'
  fi

  if [ "$signal_sent" = '1' ]; then
    return 0
  fi

  return 1
}

xmj_launch_stop_process() {
  local reason="${1:-manual}"
  local step=''

  xmj_launch_log_line "收到停止请求：$reason"

  if ! xmj_launch_process_alive; then
    xmj_launch_wait_process >/dev/null
    xmj_launch_log_line '后台进程已结束，无需额外停止。'
    return 0
  fi

  xmj_launch_send_signal 'TERM' || true
  for step in 1 2 3 4 5; do
    if ! xmj_launch_process_alive; then
      xmj_launch_wait_process >/dev/null
      xmj_launch_log_line '酒馆进程已正常结束。'
      return 0
    fi
    sleep 1
  done

  xmj_launch_log_line 'TERM 后仍未结束，准备发送 KILL。'
  xmj_launch_send_signal 'KILL' || true
  for step in 1 2 3; do
    if ! xmj_launch_process_alive; then
      xmj_launch_wait_process >/dev/null
      xmj_launch_log_line '酒馆进程已强制结束。'
      return 0
    fi
    sleep 1
  done

  xmj_launch_log_line '停止请求已发出，但暂未确认进程完全结束。'
  return 1
}

xmj_launch_log_line_count() {
  local file="${XMJ_LAUNCH_LOG_FILE:-}"
  local count='0'

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    printf '%s' '0'
    return 0
  fi

  count="$(wc -l <"$file" 2>/dev/null || true)"
  count="${count//[[:space:]]/}"

  case "$count" in
    ''|*[!0-9]*)
      count='0'
      ;;
  esac

  printf '%s' "$count"
}

xmj_launch_print_log_lines() {
  local start_line="${1:-1}"
  local end_line="${2:-0}"
  local file="${XMJ_LAUNCH_LOG_FILE:-}"
  local line=''

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 0
  fi

  if [ "$end_line" -lt "$start_line" ]; then
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    printf '  %b%s%b\n' "$XMJ_WHITE" "$line" "$XMJ_RESET"
  done < <(sed -n "${start_line},${end_line}p" "$file" 2>/dev/null)
}

xmj_launch_render_log_snapshot() {
  local snapshot_size="${1:-18}"
  local total_lines='0'
  local start_line='1'

  total_lines="$(xmj_launch_log_line_count)"
  if [ "$snapshot_size" -lt 1 ]; then
    snapshot_size='18'
  fi

  if [ "$total_lines" -gt "$snapshot_size" ]; then
    start_line=$((total_lines - snapshot_size + 1))
  fi

  if [ "$total_lines" -gt 0 ]; then
    xmj_launch_print_log_lines "$start_line" "$total_lines"
  else
    printf '  %b日志还没有输出，新的后台日志会实时追加在这里。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  fi

  XMJ_LAUNCH_LOG_CURSOR="$total_lines"
}

xmj_launch_print_new_log_lines() {
  local total_lines='0'
  local start_line='1'
  local cursor="${XMJ_LAUNCH_LOG_CURSOR:-0}"

  total_lines="$(xmj_launch_log_line_count)"
  if [ "$total_lines" -lt "$cursor" ]; then
    cursor='0'
  fi

  if [ "$total_lines" -le "$cursor" ]; then
    XMJ_LAUNCH_LOG_CURSOR="$total_lines"
    return 0
  fi

  start_line=$((cursor + 1))
  xmj_launch_print_log_lines "$start_line" "$total_lines"
  XMJ_LAUNCH_LOG_CURSOR="$total_lines"
}

xmj_launch_wait_for_running() {
  local step='0'
  local wait_limit='45'
  local should_probe='0'

  XMJ_LAUNCH_ENTRY_URL="$(xmj_launch_entry_url)"
  if xmj_launch_can_probe_url; then
    should_probe='1'
    xmj_launch_log_line "准备检测酒馆入口：${XMJ_LAUNCH_ENTRY_URL}"
  else
    xmj_launch_log_line '当前环境未检测到 curl 或 wget，将按进程存活判定启动完成。'
  fi

  for ((step = 1; step <= wait_limit; step += 1)); do
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    if ! xmj_launch_process_alive; then
      xmj_launch_wait_process >/dev/null
      xmj_launch_fail 'boot' '启动失败' '酒馆没有顺利进入运行状态，可温和查看日志。'
      return 1
    fi

    if [ "$should_probe" = '1' ]; then
      if xmj_launch_endpoint_available "$XMJ_LAUNCH_ENTRY_URL"; then
        xmj_launch_log_line "酒馆入口已可访问：${XMJ_LAUNCH_ENTRY_URL}"
        xmj_launch_log_line '酒馆进程已进入运行阶段。'
        return 0
      fi
    elif [ "$step" -ge 2 ]; then
      xmj_launch_log_line '已按后台进程存活判定进入运行阶段。'
      xmj_launch_log_line "进入链接：${XMJ_LAUNCH_ENTRY_URL}"
      return 0
    fi

    sleep 1 || true
  done

  if ! xmj_launch_process_alive; then
    xmj_launch_wait_process >/dev/null
    xmj_launch_fail 'boot' '启动失败' '酒馆没有顺利进入运行状态，可温和查看日志。'
    return 1
  fi

  if [ "$should_probe" = '1' ]; then
    xmj_launch_fail 'boot' '启动超时' '后台进程仍在运行，但酒馆入口暂时还无法访问，可温和查看日志。'
    return 1
  fi

  xmj_launch_log_line '已按后台进程存活判定进入运行阶段。'
  return 0
}

xmj_launch_handle_interrupt() {
  local summary='已停止酒馆'
  local detail='₍˄·͈༝·͈˄₎◞ 猫猫已经把这次启动的酒馆收好了，正在回到首页喵~'

  xmj_launch_log_line '检测到 Ctrl+C，准备停止本次启动的酒馆。'

  if ! xmj_launch_stop_process 'ctrl_c'; then
    summary='已发出停止请求'
    detail='₍ᐢ..ᐢ₎♡ 停止请求已经发出喵~ 如仍未结束可稍后查看日志确认。'
  fi

  xmj_render_launch_result 'stopped' 'running' "$summary" "$detail"
  sleep 1
}

xmj_launch_follow_running_log() {
  xmj_render_launch_running_screen
  xmj_launch_render_log_snapshot '18'

  while true; do
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    if ! xmj_launch_process_alive; then
      xmj_launch_print_new_log_lines
      return 0
    fi

    sleep 1 || true

    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    xmj_launch_print_new_log_lines
  done
}

xmj_launch_monitor_running() {
  local exit_code='0'
  local follow_status='0'

  xmj_launch_follow_running_log
  follow_status=$?

  if [ "$follow_status" = '130' ] || [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
    xmj_launch_handle_interrupt
    return 0
  fi

  exit_code="$(xmj_launch_wait_process)"
  xmj_launch_log_line "酒馆进程已结束，退出码：$exit_code"

  if [ "$exit_code" = '0' ]; then
    xmj_render_launch_result \
      'exited' \
      'running' \
      '酒馆已结束运行' \
      '本次运行已经结束，可按回车回到首页。'
  else
    xmj_render_launch_result \
      'failure' \
      'running' \
      '酒馆已退出' \
      '运行过程中已结束，可温和查看日志。'
  fi

  return 0
}

xmj_run_tavern_launch() {
  xmj_launch_reset_state

  xmj_render_launch_progress \
    'prepare' \
    '准备启动' \
    '₍˄·͈༝·͈˄₎◞ 猫猫正在整理启动纸条与安静日志本喵~'

  if ! xmj_launch_prepare_log_file; then
    xmj_render_launch_result \
      'failure' \
      'prepare' \
      '无法创建启动日志' \
      '请检查脚本目录的写入权限后再试。'
    return 0
  fi

  xmj_launch_log_line '开始执行 01 启动酒馆。'

  xmj_render_launch_progress \
    'env' \
    '检查环境' \
    '₍ᐢ..ᐢ₎♡ 正在确认酒馆目录与可用启动入口喵~'

  if ! xmj_launch_check_environment; then
    xmj_render_launch_result \
      'failure' \
      "$XMJ_LAUNCH_STAGE" \
      "$XMJ_LAUNCH_SUMMARY" \
      "$XMJ_LAUNCH_DETAIL"
    return 0
  fi

  if ! xmj_launch_detect_command; then
    xmj_render_launch_result \
      'failure' \
      "$XMJ_LAUNCH_STAGE" \
      "$XMJ_LAUNCH_SUMMARY" \
      "$XMJ_LAUNCH_DETAIL"
    return 0
  fi

  xmj_launch_install_int_trap

  xmj_render_launch_progress \
    'boot' \
    '启动中' \
    '₍˄·͈༝·͈˄₎◞ 猫猫正在把酒馆悄悄放到后台运行喵~'

  if ! xmj_launch_start_process; then
    xmj_launch_restore_int_trap
    xmj_render_launch_result \
      'failure' \
      "$XMJ_LAUNCH_STAGE" \
      "$XMJ_LAUNCH_SUMMARY" \
      "$XMJ_LAUNCH_DETAIL"
    return 0
  fi

  if ! xmj_launch_wait_for_running; then
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      xmj_launch_handle_interrupt
      xmj_launch_restore_int_trap
      return 0
    fi

    xmj_launch_restore_int_trap
    xmj_render_launch_result \
      'failure' \
      "$XMJ_LAUNCH_STAGE" \
      "$XMJ_LAUNCH_SUMMARY" \
      "$XMJ_LAUNCH_DETAIL"
    return 0
  fi

  xmj_launch_monitor_running
  xmj_launch_restore_int_trap
  return 0
}

xmj_run_tavern_launch_headless() {
  xmj_launch_reset_state

  if ! xmj_launch_prepare_log_file; then
    return 1
  fi

  xmj_launch_log_line '开始执行开机自启动。'

  if ! xmj_launch_check_environment; then
    return 1
  fi

  if ! xmj_launch_detect_command; then
    return 1
  fi

  if ! xmj_launch_start_process; then
    return 1
  fi

  if ! xmj_launch_wait_for_running; then
    return 1
  fi

  xmj_launch_log_line "开机自启动已完成：$(xmj_launch_entry_url)"
  return 0
}
