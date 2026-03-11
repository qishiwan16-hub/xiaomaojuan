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
  XMJ_LAUNCH_RUNTIME_FILE=''
  XMJ_LAUNCH_RUNTIME_PENDING_FILE=''
  XMJ_LAUNCH_LOG_CURSOR='0'
  XMJ_LAUNCH_RUNTIME_LOG_START='0'
  XMJ_LAUNCH_READY_SCAN_LINE='1'
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
  XMJ_LAUNCH_IMPORT_ASSERT_RETRY='0'
  XMJ_LAUNCH_START_SH_FALLBACK_USED='0'
  XMJ_LAUNCH_LOG_VIEW_STARTED='0'
  XMJ_LAUNCH_RUNNING_NOTICE_SHOWN='0'
  XMJ_LAUNCH_ATTACHED_MODE='0'
  XMJ_LAUNCH_PREVIOUS_INT_TRAP=''
  XMJ_LAUNCH_STREAM_PIPE=''
  XMJ_LAUNCH_STREAM_PID=''
  XMJ_LAUNCH_STREAM_READY_FILE=''
  XMJ_LAUNCH_STREAM_FRONTEND_FILE=''
  XMJ_LAUNCH_STREAM_DIRECT='0'
}

xmj_launch_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_LAUNCH_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_launch_timestamp)" "$line" >>"$XMJ_LAUNCH_LOG_FILE"
}

xmj_launch_runtime_stream_enabled() {
  if [ "${XMJ_LAUNCH_STREAM_DIRECT:-0}" != '1' ]; then
    return 1
  fi

  if [ -z "${XMJ_LAUNCH_STREAM_PIPE:-}" ] || [ ! -p "${XMJ_LAUNCH_STREAM_PIPE:-}" ]; then
    return 1
  fi

  return 0
}

xmj_launch_runtime_output_target() {
  if xmj_launch_runtime_stream_enabled \
    && [ -n "${XMJ_LAUNCH_STREAM_PID:-}" ] \
    && kill -0 "${XMJ_LAUNCH_STREAM_PID}" 2>/dev/null; then
    printf '%s' "${XMJ_LAUNCH_STREAM_PIPE}"
    return 0
  fi

  printf '%s' "${XMJ_LAUNCH_RUNTIME_FILE:-$XMJ_LAUNCH_LOG_FILE}"
}

xmj_launch_flush_pending_runtime_output() {
  if [ -z "${XMJ_LAUNCH_RUNTIME_PENDING_FILE:-}" ] || [ ! -s "${XMJ_LAUNCH_RUNTIME_PENDING_FILE:-}" ]; then
    return 0
  fi

  cat "${XMJ_LAUNCH_RUNTIME_PENDING_FILE}" 2>/dev/null || true
  : >"${XMJ_LAUNCH_RUNTIME_PENDING_FILE}" 2>/dev/null || true
}

xmj_launch_enable_frontend_stream_output() {
  if ! xmj_launch_runtime_stream_enabled; then
    return 0
  fi

  if [ -n "${XMJ_LAUNCH_STREAM_FRONTEND_FILE:-}" ]; then
    : >"${XMJ_LAUNCH_STREAM_FRONTEND_FILE}" 2>/dev/null || true
  fi

  xmj_launch_flush_pending_runtime_output
}

xmj_launch_start_runtime_stream_forwarder() {
  if ! xmj_launch_runtime_stream_enabled; then
    XMJ_LAUNCH_STREAM_PID=''
    return 0
  fi

  if [ -n "${XMJ_LAUNCH_STREAM_PID:-}" ] && kill -0 "${XMJ_LAUNCH_STREAM_PID}" 2>/dev/null; then
    return 0
  fi

  (
    local line=''

    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"

      if [ ! -f "${XMJ_LAUNCH_STREAM_READY_FILE:-}" ]; then
        printf '%s\n' "$line" >>"${XMJ_LAUNCH_RUNTIME_FILE}"
        continue
      fi

      if [ ! -f "${XMJ_LAUNCH_STREAM_FRONTEND_FILE:-}" ]; then
        printf '%s\n' "$line" >>"${XMJ_LAUNCH_RUNTIME_PENDING_FILE}"
        continue
      fi

      printf '%s\n' "$line"
    done < "${XMJ_LAUNCH_STREAM_PIPE}"
  ) &

  XMJ_LAUNCH_STREAM_PID="$!"
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

  XMJ_LAUNCH_RUNTIME_FILE="$XMJ_LOG_DIR/runtime-$stamp.log"
  if ! : >"$XMJ_LAUNCH_RUNTIME_FILE" 2>/dev/null; then
    return 1
  fi

  XMJ_LAUNCH_RUNTIME_PENDING_FILE="$XMJ_LOG_DIR/runtime-$stamp.pending"
  if ! : >"$XMJ_LAUNCH_RUNTIME_PENDING_FILE" 2>/dev/null; then
    return 1
  fi

  XMJ_LAUNCH_STREAM_READY_FILE="$XMJ_LOG_DIR/runtime-$stamp.ready"
  XMJ_LAUNCH_STREAM_FRONTEND_FILE="$XMJ_LOG_DIR/runtime-$stamp.frontend"
  rm -f "${XMJ_LAUNCH_STREAM_READY_FILE}" "${XMJ_LAUNCH_STREAM_FRONTEND_FILE}" 2>/dev/null || true

  if command -v mkfifo >/dev/null 2>&1; then
    XMJ_LAUNCH_STREAM_PIPE="$XMJ_LOG_DIR/runtime-$stamp.pipe"
    rm -f "${XMJ_LAUNCH_STREAM_PIPE}" 2>/dev/null || true
    if mkfifo "${XMJ_LAUNCH_STREAM_PIPE}" 2>/dev/null; then
      XMJ_LAUNCH_STREAM_DIRECT='1'
    else
      XMJ_LAUNCH_STREAM_PIPE=''
    fi
  fi

  xmj_launch_log_line '小猫卷启动日志已创建。'
  xmj_launch_log_line "目标目录：${XMJ_SILLYTAVERN_PATH:-未设置}"
  xmj_launch_log_line "运行输出文件：${XMJ_LAUNCH_RUNTIME_FILE}"
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

xmj_launch_build_url() {
  local host="${1:-127.0.0.1}"
  local port="${2:-8000}"
  local path="${3:-/}"

  case "$path" in
    '')
      path='/'
      ;;
    /*)
      ;;
    *)
      path="/$path"
      ;;
  esac

  case "$host" in
    \[*\])
      ;;
    *:*)
      host="[$host]"
      ;;
  esac

  printf 'http://%s:%s%s' "$host" "$port" "$path"
}

xmj_launch_entry_url() {
  local host=''
  local port="${XMJ_TAVERN_PORT:-8000}"
  local path="${XMJ_TAVERN_ENTRY_PATH:-/}"

  host="$(xmj_launch_access_host)"
  xmj_launch_build_url "$host" "$port" "$path"
}

xmj_launch_latest_log_file() {
  local log_dir="${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}"
  local file=''

  if [ -d "$log_dir" ]; then
    file="$(ls -1t "$log_dir"/launch-*.log 2>/dev/null | head -n 1)"
  fi

  printf '%s' "$file"
}

xmj_launch_extract_pid_from_log() {
  local log_file="${1:-}"
  local pid=''

  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    printf '%s' ''
    return 0
  fi

  pid="$(sed -n 's/.*后台进程 PID：\([0-9][0-9]*\).*/\1/p' "$log_file" 2>/dev/null | tail -n 1)"
  printf '%s' "$pid"
}

xmj_launch_extract_entry_url_from_log() {
  local log_file="${1:-}"
  local url=''

  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    printf '%s' ''
    return 0
  fi

  url="$(tr -d '\r' < "$log_file" 2>/dev/null | sed -n \
    -e 's/.*[Gg]o to:[[:space:]]*\(http[^[:space:]]*\).*/\1/p' \
    -e 's/.*入口.*\(http[^[:space:]]*\).*/\1/p' \
    -e 's/.*进入链接.*\(http[^[:space:]]*\).*/\1/p' \
    | tail -n 1)"
  printf '%s' "$url"
}

xmj_launch_extract_runtime_file_from_log() {
  local log_file="${1:-}"
  local runtime_file=''

  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    printf '%s' ''
    return 0
  fi

  runtime_file="$(sed -n 's/.*运行输出文件：\(.*\)$/\1/p' "$log_file" 2>/dev/null | tail -n 1)"
  printf '%s' "$runtime_file"
}

xmj_launch_runtime_marker_text() {
  printf '%s' '__XMJ_RUNTIME_LOG_START__'
}

xmj_launch_extract_runtime_log_start() {
  local log_file="${1:-}"
  local marker_line=''
  local marker_text=''
  local success_line=''
  local runtime_start=''

  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    printf '%s' '0'
    return 0
  fi

  marker_text="$(xmj_launch_runtime_marker_text)"
  marker_line="$(grep -nF "$marker_text" "$log_file" 2>/dev/null | tail -n 1)"
  marker_line="${marker_line%%:*}"
  runtime_start="$(sed -n 's/.*运行输出起始行：\([0-9][0-9]*\)$/\1/p' "$log_file" 2>/dev/null | tail -n 1)"

  case "$runtime_start" in
    ''|*[!0-9]*)
      ;;
    *)
      printf '%s' "$runtime_start"
      return 0
      ;;
  esac

  case "$marker_line" in
    ''|*[!0-9]*)
      success_line="$(sed -n \
        -e '/[Gg]o to:[[:space:]]*http/=' \
        -e '/后台日志已显示酒馆入口，按日志判定进入运行阶段。/=' \
        -e '/酒馆入口已可访问：/=' \
        -e '/酒馆进程已进入运行阶段。/=' \
        -e '/已按后台进程存活判定进入运行阶段。/=' \
        "$log_file" 2>/dev/null | tail -n 1)"
      case "$success_line" in
        ''|*[!0-9]*)
          printf '%s' '0'
          return 0
          ;;
      esac

      printf '%s' "$((success_line + 1))"
      return 0
      ;;
  esac

  printf '%s' "$((marker_line + 1))"
}

xmj_launch_normalize_runtime_url() {
  local url="${1:-}"
  local access_host=''

  if [ -z "$url" ]; then
    printf '%s' ''
    return 1
  fi

  access_host="$(xmj_launch_access_host)"
  url="$(printf '%s' "$url" | sed \
    -e "s#://0\\.0\\.0\\.0:#://${access_host}:#g" \
    -e 's#://\[::\]:#://127.0.0.1:#g' \
    -e 's#://localhost:#://127.0.0.1:#g')"

  printf '%s' "$url"
}

xmj_launch_detect_runtime_entry_url_from_log() {
  local file="${XMJ_LAUNCH_RUNTIME_FILE:-${XMJ_LAUNCH_LOG_FILE:-}}"
  local start_line="${XMJ_LAUNCH_READY_SCAN_LINE:-1}"
  local total_lines='0'
  local url=''

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    printf '%s' ''
    return 1
  fi

  total_lines="$(xmj_launch_log_line_count "$file")"
  case "$start_line" in
    ''|*[!0-9]*)
      start_line='1'
      ;;
  esac

  if [ "$start_line" -lt 1 ]; then
    start_line='1'
  fi

  if [ "$total_lines" -lt "$start_line" ]; then
    start_line='1'
  fi

  url="$(sed -n "${start_line},\$p" "$file" 2>/dev/null | tr -d '\r' | sed -n \
    -e 's/.*[Gg]o to:[[:space:]]*\(http[^[:space:]]*\).*/\1/p' \
    -e 's/.*入口.*\(http[^[:space:]]*\).*/\1/p' \
    -e 's/.*进入链接.*\(http[^[:space:]]*\).*/\1/p' \
    | tail -n 1)"

  XMJ_LAUNCH_READY_SCAN_LINE=$((total_lines + 1))
  url="$(xmj_launch_normalize_runtime_url "$url" || true)"

  if [ -n "$url" ]; then
    printf '%s' "$url"
    return 0
  fi

  printf '%s' ''
  return 1
}

xmj_launch_file_has_go_to_signal() {
  local log_file="${1:-}"

  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    return 1
  fi

  tr -d '\r' < "$log_file" 2>/dev/null | grep -aEq '[Gg]o to:[[:space:]]*http'
}

xmj_launch_detect_ready_entry_url() {
  local detected_url=''
  local fallback_url=''
  local default_url=''
  local file=''

  detected_url="$(xmj_launch_detect_runtime_entry_url_from_log || true)"
  if [ -n "$detected_url" ]; then
    printf '%s' "$detected_url"
    return 0
  fi

  default_url="$(xmj_launch_normalize_runtime_url "${XMJ_LAUNCH_ENTRY_URL:-$(xmj_launch_entry_url)}" || true)"
  for file in "${XMJ_LAUNCH_RUNTIME_FILE:-}" "${XMJ_LAUNCH_LOG_FILE:-}"; do
    if [ -z "$file" ] || [ ! -f "$file" ]; then
      continue
    fi

    fallback_url="$(xmj_launch_extract_entry_url_from_log "$file" || true)"
    fallback_url="$(xmj_launch_normalize_runtime_url "$fallback_url" || true)"
    if [ -n "$fallback_url" ]; then
      printf '%s' "$fallback_url"
      return 0
    fi

    if xmj_launch_file_has_go_to_signal "$file"; then
      if [ -n "$default_url" ]; then
        printf '%s' "$default_url"
        return 0
      fi

      printf '%s' "$(xmj_launch_entry_url)"
      return 0
    fi
  done

  printf '%s' ''
  return 1
}

xmj_launch_probe_candidate_urls() {
  local port="${XMJ_TAVERN_PORT:-8000}"
  local path="${XMJ_TAVERN_ENTRY_PATH:-/}"
  local access_host=''
  local candidate=''
  local seen='|'

  access_host="$(xmj_launch_access_host)"

  for candidate in \
    "${XMJ_LAUNCH_ENTRY_URL:-}" \
    "$(xmj_launch_build_url "$access_host" "$port" "$path")" \
    "$(xmj_launch_build_url "$access_host" "$port" "/")" \
    "$(xmj_launch_build_url '127.0.0.1' "$port" "$path")" \
    "$(xmj_launch_build_url '127.0.0.1' "$port" "/")" \
    "$(xmj_launch_build_url 'localhost' "$port" "$path")" \
    "$(xmj_launch_build_url 'localhost' "$port" "/")"; do
    if [ -z "$candidate" ]; then
      continue
    fi

    case "$seen" in
      *"|$candidate|"*)
        continue
        ;;
    esac

    seen="${seen}${candidate}|"
    printf '%s\n' "$candidate"
  done
}
xmj_launch_wait_limit_seconds() {
  printf '%s' '300'
}

xmj_launch_slow_notice_seconds() {
  printf '%s' '150'
}

xmj_launch_probe_fallback_seconds() {
  printf '%s' '120'
}

xmj_launch_extract_use_pgid_from_log() {
  local log_file="${1:-}"

  if [ -n "$log_file" ] && [ -f "$log_file" ] && grep -q '已使用 setsid 创建独立进程组。' "$log_file" 2>/dev/null; then
    printf '%s' '1'
    return 0
  fi

  printf '%s' '0'
}

xmj_launch_attach_latest_session() {
  local log_file=''

  log_file="$(xmj_launch_latest_log_file)"
  if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
    return 1
  fi

  XMJ_LAUNCH_LOG_FILE="$log_file"
  XMJ_LAUNCH_RUNTIME_FILE="$(xmj_launch_extract_runtime_file_from_log "$log_file")"
  XMJ_LAUNCH_PID="$(xmj_launch_extract_pid_from_log "$log_file")"
  XMJ_LAUNCH_ENTRY_URL="$(xmj_launch_extract_entry_url_from_log "$log_file")"
  XMJ_LAUNCH_RUNTIME_LOG_START="$(xmj_launch_extract_runtime_log_start "$log_file")"
  XMJ_LAUNCH_USE_PGID="$(xmj_launch_extract_use_pgid_from_log "$log_file")"
  XMJ_LAUNCH_ATTACHED_MODE='1'

  if [ -z "${XMJ_LAUNCH_ENTRY_URL:-}" ] && [ -n "${XMJ_LAUNCH_RUNTIME_FILE:-}" ]; then
    XMJ_LAUNCH_ENTRY_URL="$(xmj_launch_extract_entry_url_from_log "$XMJ_LAUNCH_RUNTIME_FILE")"
  fi

  if [ -z "${XMJ_LAUNCH_ENTRY_URL:-}" ]; then
    XMJ_LAUNCH_ENTRY_URL="$(xmj_launch_entry_url)"
  fi

  return 0
}

xmj_launch_mark_runtime_log_start() {
  local total_lines='0'

  total_lines="$(xmj_launch_log_line_count "${XMJ_LAUNCH_RUNTIME_FILE:-}")"
  XMJ_LAUNCH_RUNTIME_LOG_START=$((total_lines + 1))
  XMJ_LAUNCH_LOG_CURSOR='0'
  if [ -n "${XMJ_LAUNCH_STREAM_READY_FILE:-}" ]; then
    : >"${XMJ_LAUNCH_STREAM_READY_FILE}" 2>/dev/null || true
  fi
  xmj_launch_log_line "运行输出起始行：${XMJ_LAUNCH_RUNTIME_LOG_START}"
  xmj_launch_log_line '运行输出已切换到前台直显，不再继续写入启动日志。'
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
    curl -sS --connect-timeout 1 --max-time 2 -o /dev/null "$url" >/dev/null 2>&1
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -T 2 -O /dev/null "$url" >/dev/null 2>&1
    return $?
  fi

  return 1
}

xmj_launch_session_running() {
  if [ -n "${XMJ_LAUNCH_PID:-}" ] && xmj_launch_process_alive; then
    return 0
  fi

  if [ -n "${XMJ_LAUNCH_ENTRY_URL:-}" ] \
    && xmj_launch_can_probe_url \
    && xmj_launch_endpoint_available "${XMJ_LAUNCH_ENTRY_URL}"; then
    return 0
  fi

  return 1
}

xmj_launch_confirm_ready_state() {
  local url="${1:-${XMJ_LAUNCH_ENTRY_URL:-}}"
  local attempt='0'

  if [ -z "$url" ]; then
    return 1
  fi

  if ! xmj_launch_can_probe_url; then
    xmj_launch_process_alive
    return $?
  fi

  for attempt in 1 2 3 4 5; do
    if xmj_launch_endpoint_available "$url"; then
      return 0
    fi

    if ! xmj_launch_process_alive; then
      return 1
    fi

    sleep 1 || true
  done

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
  exact_tag="$(git -C "$repo_path" tag --points-at HEAD 2>>"$XMJ_LAUNCH_LOG_FILE" | head -n 1 || true)"

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

xmj_launch_file_has_legacy_import_assertion() {
  local file_path="${1:-}"
  local line=''
  local in_import='0'
  local import_lines='0'

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_import" != '1' ]; then
      if [[ "$line" =~ ^[[:space:]]*import([[:space:]]|\{|\"|\') ]]; then
        in_import='1'
        import_lines='1'
      else
        continue
      fi
    else
      import_lines=$((import_lines + 1))
    fi

    if [[ "$line" =~ assert[[:space:]]*\{ ]]; then
      return 0
    fi

    if [[ "$line" =~ \;[[:space:]]*$ ]] || [ "$import_lines" -ge 8 ]; then
      in_import='0'
      import_lines='0'
    fi
  done <"$file_path"

  return 1
}

xmj_launch_list_legacy_import_assertion_candidates_in_path() {
  local search_root="${1:-}"
  local exclude_node_modules="${2:-1}"
  local -a rg_args=()
  local -a grep_args=()

  if [ -z "$search_root" ] || [ ! -d "$search_root" ]; then
    return 0
  fi

  if command -v rg >/dev/null 2>&1; then
    rg_args=(
      -l
      --no-messages
      -g '*.js'
      -g '*.mjs'
      -g '*.cjs'
      -g '!.git/**'
      -g '!.next/**'
      -g '!dist/**'
    )
    if [ "$exclude_node_modules" = '1' ]; then
      rg_args+=(-g '!node_modules/**')
    fi

    rg "${rg_args[@]}" 'assert[[:space:]]*\{' "$search_root" 2>/dev/null || true
    return 0
  fi

  if command -v grep >/dev/null 2>&1; then
    grep_args=(
      -RIlE
      --include='*.js'
      --include='*.mjs'
      --include='*.cjs'
      --exclude-dir='.git'
      --exclude-dir='.next'
      --exclude-dir='dist'
    )
    if [ "$exclude_node_modules" = '1' ]; then
      grep_args+=(--exclude-dir='node_modules')
    fi

    grep "${grep_args[@]}" 'assert[[:space:]]*\{' "$search_root" 2>/dev/null || true
    return 0
  fi

  if [ "$exclude_node_modules" = '1' ]; then
    find "$search_root" \
      \( -path "$search_root/.git" -o -path "$search_root/node_modules" -o -path "$search_root/.next" -o -path "$search_root/dist" \) -prune \
      -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) -exec grep -IlE 'assert[[:space:]]*\{' {} + 2>/dev/null || true
    return 0
  fi

  find "$search_root" \
    \( -path "$search_root/.git" -o -path "$search_root/.next" -o -path "$search_root/dist" \) -prune \
    -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) -exec grep -IlE 'assert[[:space:]]*\{' {} + 2>/dev/null || true
  return 0
}

xmj_launch_list_legacy_import_assertion_candidates() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  xmj_launch_list_legacy_import_assertion_candidates_in_path "$repo_path" '1'
}

xmj_launch_list_dependency_legacy_import_assertion_candidates() {
  local dependency_root="${XMJ_SILLYTAVERN_PATH%/}/node_modules"

  xmj_launch_list_legacy_import_assertion_candidates_in_path "$dependency_root" '0'
}

xmj_launch_find_legacy_import_assertion_file() {
  local file_path=''

  while IFS= read -r file_path || [ -n "$file_path" ]; do
    if xmj_launch_file_has_legacy_import_assertion "$file_path"; then
      printf '%s' "$file_path"
      return 0
    fi
  done < <(xmj_launch_list_legacy_import_assertion_candidates)

  printf '%s' ''
}

xmj_launch_find_dependency_legacy_import_assertion_file() {
  local file_path=''

  while IFS= read -r file_path || [ -n "$file_path" ]; do
    if xmj_launch_file_has_legacy_import_assertion "$file_path"; then
      printf '%s' "$file_path"
      return 0
    fi
  done < <(xmj_launch_list_dependency_legacy_import_assertion_candidates)

  printf '%s' ''
}

xmj_launch_patch_import_assertion_file() {
  local file_path="${1:-}"
  local temp_file=''
  local line=''
  local new_line=''
  local in_import='0'
  local import_lines='0'
  local updated='0'

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    return 1
  fi

  temp_file="${file_path}.tmp.$$"
  if ! : >"$temp_file" 2>/dev/null; then
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    new_line="$line"

    if [ "$in_import" != '1' ]; then
      if [[ "$line" =~ ^[[:space:]]*import([[:space:]]|\{|\"|\') ]]; then
        in_import='1'
        import_lines='1'
      fi
    else
      import_lines=$((import_lines + 1))
    fi

    if [ "$in_import" = '1' ] && [[ "$line" =~ assert[[:space:]]*\{ ]]; then
      new_line="$(printf '%s\n' "$line" | sed 's/assert[[:space:]]*{/with {/')"
      if [ "$new_line" != "$line" ]; then
        updated='1'
      fi
    fi

    if ! printf '%s\n' "$new_line" >>"$temp_file"; then
      rm -f "$temp_file" 2>/dev/null || true
      return 1
    fi

    if [ "$in_import" = '1' ] && { [[ "$line" =~ \;[[:space:]]*$ ]] || [ "$import_lines" -ge 8 ]; }; then
      in_import='0'
      import_lines='0'
    fi
  done <"$file_path"

  if [ "$updated" != '1' ]; then
    rm -f "$temp_file" 2>/dev/null || true
    return 0
  fi

  if ! xmj_replace_file_with_temp "$temp_file" "$file_path"; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  return 0
}

xmj_launch_auto_fix_import_assertions_in_scope() {
  local scope="${1:-repo}"
  local file_path=''
  local fixed_count='0'

  while IFS= read -r file_path || [ -n "$file_path" ]; do
    if ! xmj_launch_file_has_legacy_import_assertion "$file_path"; then
      continue
    fi

    if ! xmj_launch_patch_import_assertion_file "$file_path"; then
      xmj_launch_log_line "旧 import assert 自动修复失败：${file_path}"
      return 1
    fi

    fixed_count=$((fixed_count + 1))
    xmj_launch_log_line "已自动修复旧 import assert 语法：${file_path}"

    if xmj_launch_file_has_legacy_import_assertion "$file_path"; then
      xmj_launch_log_line "旧 import assert 自动修复后仍未通过复检：${file_path}"
      return 1
    fi
  done < <(
    case "$scope" in
      dependencies)
        xmj_launch_list_dependency_legacy_import_assertion_candidates
        ;;
      *)
        xmj_launch_list_legacy_import_assertion_candidates
        ;;
    esac
  )

  [ "$fixed_count" -gt 0 ]
}

xmj_launch_auto_fix_import_assertions() {
  xmj_launch_auto_fix_import_assertions_in_scope 'repo'
}

xmj_launch_auto_fix_dependency_import_assertions() {
  xmj_launch_auto_fix_import_assertions_in_scope 'dependencies'
}

xmj_launch_check_import_assertion_compat() {
  local node_version=''
  local node_major=''
  local legacy_file=''
  local short_file=''

  if ! command -v node >/dev/null 2>&1; then
    return 0
  fi

  if ! declare -F xmj_node_major_version >/dev/null 2>&1; then
    return 0
  fi

  node_version="$(node -v 2>/dev/null || true)"
  node_major="$(xmj_node_major_version "$node_version" || true)"

  if [ -z "$node_major" ] || [ "$node_major" -lt 22 ]; then
    return 0
  fi

  legacy_file="$(xmj_launch_find_legacy_import_assertion_file)"
  if [ -z "$legacy_file" ]; then
    return 0
  fi

  xmj_launch_log_line "检测到旧 import assert 语法，准备自动修复：${legacy_file}"
  if xmj_launch_auto_fix_import_assertions; then
    legacy_file="$(xmj_launch_find_legacy_import_assertion_file)"
    if [ -z "$legacy_file" ]; then
      xmj_launch_log_line '旧 import assert 语法已自动改成 with，继续启动。'
      return 0
    fi
  fi

  short_file="${legacy_file#${XMJ_SILLYTAVERN_PATH%/}/}"
  xmj_launch_fail \
    'env' \
    '旧 import assert 语法自动修复失败' \
    "当前是 ${node_version}，而 ${short_file:-$legacy_file} 里还在用 import ... assert { type: 'json' }。请手动改成 with { type: 'json' }，或换回 Node 20.x。"
  return 1
}

xmj_launch_log_has_unexpected_token_brace() {
  local file="${XMJ_LAUNCH_LOG_FILE:-}"

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 1
  fi

  grep -Fq "Unexpected token '{'" "$file" 2>/dev/null
}

xmj_launch_try_recover_dependency_import_assertion_failure() {
  local node_version=''
  local node_major=''
  local legacy_file=''
  local scope=''

  if [ "${XMJ_LAUNCH_IMPORT_ASSERT_RETRY:-0}" = '1' ]; then
    return 1
  fi

  if ! xmj_launch_log_has_unexpected_token_brace; then
    return 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi

  if ! declare -F xmj_node_major_version >/dev/null 2>&1; then
    return 1
  fi

  node_version="$(node -v 2>/dev/null || true)"
  node_major="$(xmj_node_major_version "$node_version" || true)"
  if [ -z "$node_major" ] || [ "$node_major" -lt 22 ]; then
    return 1
  fi

  for scope in repo dependencies; do
    case "$scope" in
      repo)
        legacy_file="$(xmj_launch_find_legacy_import_assertion_file)"
        if [ -z "$legacy_file" ]; then
          continue
        fi
        xmj_launch_log_line "启动失败后在仓库目录检测到旧 import assert 语法：${legacy_file}"
        if ! xmj_launch_auto_fix_import_assertions; then
          return 1
        fi
        legacy_file="$(xmj_launch_find_legacy_import_assertion_file)"
        if [ -n "$legacy_file" ]; then
          xmj_launch_log_line "仓库目录里仍残留旧 import assert 语法：${legacy_file}"
          return 1
        fi
        XMJ_LAUNCH_IMPORT_ASSERT_RETRY='1'
        xmj_launch_log_line '已完成仓库目录旧 import assert 自动修复，准备重新启动酒馆。'
        return 0
        ;;
      *)
        legacy_file="$(xmj_launch_find_dependency_legacy_import_assertion_file)"
        if [ -z "$legacy_file" ]; then
          continue
        fi
        xmj_launch_log_line "启动失败后在依赖目录检测到旧 import assert 语法：${legacy_file}"
        if ! xmj_launch_auto_fix_dependency_import_assertions; then
          return 1
        fi
        legacy_file="$(xmj_launch_find_dependency_legacy_import_assertion_file)"
        if [ -n "$legacy_file" ]; then
          xmj_launch_log_line "依赖目录里仍残留旧 import assert 语法：${legacy_file}"
          return 1
        fi
        XMJ_LAUNCH_IMPORT_ASSERT_RETRY='1'
        xmj_launch_log_line '已完成依赖目录旧 import assert 自动修复，准备重新启动酒馆。'
        return 0
        ;;
    esac
  done

  return 1
}

xmj_launch_check_node_runtime() {
  local node_version=''
  local runtime_issue=''
  local fix_hint=''

  if ! command -v node >/dev/null 2>&1; then
    return 0
  fi

  node_version="$(node -v 2>/dev/null || true)"
  if [ -z "$node_version" ]; then
    node_version='unknown'
  fi

  xmj_launch_log_line "Node.js 版本：${node_version}"

  if ! declare -F xmj_node_runtime_issue >/dev/null 2>&1; then
    return 0
  fi

  runtime_issue="$(xmj_node_runtime_issue "$node_version" || true)"
  if [ -z "$runtime_issue" ]; then
    return 0
  fi

  fix_hint='请先进入 13 异常修复，或在 Termux 执行 pkg install nodejs-lts。'
  if declare -F xmj_node_runtime_fix_hint >/dev/null 2>&1; then
    fix_hint="$(xmj_node_runtime_fix_hint)"
  fi

  xmj_launch_fail \
    'env' \
    'Node.js 版本不适合当前酒馆环境' \
    "${runtime_issue} ${fix_hint} 这类环境常见表现就是启动时报 Unexpected token '{'。"
  return 1
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
  if ! xmj_launch_check_node_runtime; then
    return 1
  fi
  xmj_launch_log_line '酒馆目录检查通过。'
  return 0
}

xmj_launch_detect_node_entry_file() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local candidate=''

  if [ -z "$repo_path" ]; then
    printf '%s' ''
    return 1
  fi

  for candidate in \
    'server-main.js' \
    'server.js' \
    'dist/server-main.js' \
    'dist/server.js' \
    'src/server-main.js' \
    'src/server.js'
  do
    if [ -f "$repo_path/$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  printf '%s' ''
  return 1
}

xmj_launch_detect_command() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local package_json=''
  local node_entry_file=''

  package_json="$repo_path/package.json"

  if [ -f "$repo_path/start.sh" ]; then
    XMJ_LAUNCH_METHOD='start_sh'
    XMJ_LAUNCH_METHOD_TEXT='bash ./start.sh'
    XMJ_LAUNCH_COMMAND='bash ./start.sh'
    XMJ_LAUNCH_ENTRY_FILE='start.sh'
    xmj_launch_log_line '检测到 start.sh，本次按酒馆原生启动方式执行。'
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
    xmj_launch_log_line '检测到 package.json 的 start 脚本，本次按酒馆原生启动方式执行。'
    return 0
  fi

  node_entry_file="$(xmj_launch_detect_node_entry_file || true)"
  if [ -n "$node_entry_file" ]; then
    if ! command -v node >/dev/null 2>&1; then
      xmj_launch_fail 'env' '未检测到 Node.js' "检测到 ${node_entry_file}，但当前环境无法执行 node。"
      return 1
    fi

    XMJ_LAUNCH_METHOD='node_entry'
    XMJ_LAUNCH_METHOD_TEXT="node ./${node_entry_file}"
    XMJ_LAUNCH_COMMAND="node ./${node_entry_file}"
    XMJ_LAUNCH_ENTRY_FILE="$node_entry_file"
    xmj_launch_log_line "未找到酒馆原生启动脚本，回退使用 node ./${node_entry_file}。"
    return 0
  fi

  xmj_launch_fail 'env' '未识别到可用启动入口' '未找到 server-main.js、server.js、package.json 的 start 脚本或 start.sh。'
  return 1
}

xmj_launch_try_start_sh_fallback() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ "${XMJ_LAUNCH_METHOD:-}" != 'node_entry' ]; then
    return 1
  fi

  if [ "${XMJ_LAUNCH_START_SH_FALLBACK_USED:-0}" = '1' ]; then
    return 1
  fi

  if [ -z "$repo_path" ] || [ ! -f "$repo_path/start.sh" ]; then
    return 1
  fi

  XMJ_LAUNCH_START_SH_FALLBACK_USED='1'
  XMJ_LAUNCH_METHOD='start_sh'
  XMJ_LAUNCH_METHOD_TEXT='bash ./start.sh'
  XMJ_LAUNCH_COMMAND='bash ./start.sh'
  XMJ_LAUNCH_ENTRY_FILE='start.sh'
  xmj_launch_log_line '直启 Node 主入口未成功，已自动回退为 bash ./start.sh 重试。'
  return 0
}

xmj_launch_merged_node_options() {
  local memory_limit_mb="${XMJ_TAVERN_NODE_MEMORY_MB:-0}"
  local current_options="${NODE_OPTIONS:-}"
  local merged_options=''
  local option=''
  local memory_option=''

  case "$memory_limit_mb" in
    ''|*[!0-9]*)
      printf '%s' "$current_options"
      return 0
      ;;
  esac

  if [ "$memory_limit_mb" -lt 1 ]; then
    printf '%s' "$current_options"
    return 0
  fi

  memory_option="--max-old-space-size=${memory_limit_mb}"
  for option in $current_options; do
    case "$option" in
      --max-old-space-size=*)
        continue
        ;;
    esac

    if [ -n "$merged_options" ]; then
      merged_options="${merged_options} ${option}"
    else
      merged_options="$option"
    fi
  done

  if [ -n "$merged_options" ]; then
    printf '%s %s' "$merged_options" "$memory_option"
    return 0
  fi

  printf '%s' "$memory_option"
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

  if [ "${XMJ_LAUNCH_ATTACHED_MODE:-0}" = '1' ]; then
    case "${XMJ_LAUNCH_EXIT_CODE:-}" in
      ''|*[!0-9-]*)
        XMJ_LAUNCH_EXIT_CODE='0'
        ;;
    esac
    XMJ_LAUNCH_WAITED='1'
    printf '%s' "${XMJ_LAUNCH_EXIT_CODE:-0}"
    return 0
  fi

  wait "$pid" 2>/dev/null
  exit_code=$?
  if [ -n "${XMJ_LAUNCH_STREAM_PID:-}" ]; then
    wait "${XMJ_LAUNCH_STREAM_PID}" 2>/dev/null || true
    XMJ_LAUNCH_STREAM_PID=''
  fi
  XMJ_LAUNCH_EXIT_CODE="$exit_code"
  XMJ_LAUNCH_WAITED='1'
  printf '%s' "$exit_code"
}

xmj_launch_start_process() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local merged_node_options=''
  local output_target=''

  if [ -z "${XMJ_LAUNCH_COMMAND:-}" ]; then
    xmj_launch_fail 'boot' '缺少启动命令' '当前还没有识别出可用的酒馆启动方式。'
    return 1
  fi

  XMJ_LAUNCH_WAITED='0'
  XMJ_LAUNCH_EXIT_CODE=''
  XMJ_LAUNCH_USE_PGID='0'
  merged_node_options="$(xmj_launch_merged_node_options)"

  if [ -n "$merged_node_options" ]; then
    xmj_launch_log_line "已附加 NODE_OPTIONS：${merged_node_options}"
  else
    xmj_launch_log_line '当前未附加额外的 Node 内存参数。'
  fi
  xmj_launch_start_runtime_stream_forwarder
  output_target="$(xmj_launch_runtime_output_target)"

  if command -v setsid >/dev/null 2>&1; then
    (
      cd "$repo_path" || exit 1
      if [ -n "$merged_node_options" ]; then
        export NODE_OPTIONS="$merged_node_options"
      fi
      if command -v script >/dev/null 2>&1; then
        exec setsid script -qefc "${XMJ_LAUNCH_COMMAND}" "${output_target}" >/dev/null 2>&1 </dev/null
      fi
      case "${XMJ_LAUNCH_METHOD:-}" in
        node_entry)
          exec setsid node "$XMJ_LAUNCH_ENTRY_FILE" </dev/null
          ;;
        npm_start)
          exec setsid npm run start </dev/null
          ;;
        start_sh)
          exec setsid bash ./start.sh </dev/null
          ;;
        *)
          exec setsid bash -lc "exec ${XMJ_LAUNCH_COMMAND}" </dev/null
          ;;
      esac
    ) >>"${output_target}" 2>&1 &
    XMJ_LAUNCH_USE_PGID='1'
    if command -v script >/dev/null 2>&1; then
      xmj_launch_log_line '已使用 script + setsid 保留运行期原生终端输出。'
    else
      xmj_launch_log_line '已使用 setsid 创建独立进程组。'
    fi
  else
    (
      cd "$repo_path" || exit 1
      if [ -n "$merged_node_options" ]; then
        export NODE_OPTIONS="$merged_node_options"
      fi
      if command -v script >/dev/null 2>&1; then
        exec script -qefc "${XMJ_LAUNCH_COMMAND}" "${output_target}" >/dev/null 2>&1 </dev/null
      fi
      case "${XMJ_LAUNCH_METHOD:-}" in
        node_entry)
          exec node "$XMJ_LAUNCH_ENTRY_FILE" </dev/null
          ;;
        npm_start)
          exec npm run start </dev/null
          ;;
        start_sh)
          exec bash ./start.sh </dev/null
          ;;
        *)
          exec bash -lc "exec ${XMJ_LAUNCH_COMMAND}" </dev/null
          ;;
      esac
    ) >>"${output_target}" 2>&1 &
    if command -v script >/dev/null 2>&1; then
      xmj_launch_log_line '当前环境未检测到 setsid，已使用 script 保留运行期原生终端输出。'
    else
      xmj_launch_log_line '当前环境未检测到 setsid，已退回普通后台启动。'
    fi
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

xmj_launch_display_log_file() {
  if [ -n "${XMJ_LAUNCH_RUNTIME_FILE:-}" ] && [ -f "${XMJ_LAUNCH_RUNTIME_FILE:-}" ]; then
    printf '%s' "${XMJ_LAUNCH_RUNTIME_FILE}"
    return 0
  fi

  printf '%s' "${XMJ_LAUNCH_LOG_FILE:-}"
}

xmj_launch_log_line_count() {
  local file="${1:-}"
  local count='0'

  if [ -z "$file" ]; then
    file="$(xmj_launch_display_log_file)"
  fi

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
  local file="${3:-}"
  local line=''

  if [ -z "$file" ]; then
    file="$(xmj_launch_display_log_file)"
  fi

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 0
  fi

  if [ "$end_line" -lt "$start_line" ]; then
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    printf '  %s%b\n' "$line" "$XMJ_RESET"
  done < <(sed -n "${start_line},${end_line}p" "$file" 2>/dev/null)
}

xmj_launch_render_log_snapshot() {
  local snapshot_size="${1:-18}"
  local file=''
  local total_lines='0'
  local start_line='1'
  local runtime_start="${XMJ_LAUNCH_RUNTIME_LOG_START:-0}"

  file="$(xmj_launch_display_log_file)"

  total_lines="$(xmj_launch_log_line_count "$file")"
  if [ "$snapshot_size" -lt 1 ]; then
    snapshot_size='18'
  fi

  case "$runtime_start" in
    ''|*[!0-9]*)
      runtime_start='0'
      ;;
  esac

  if [ "$total_lines" -gt "$snapshot_size" ]; then
    start_line=$((total_lines - snapshot_size + 1))
  fi

  if [ "$runtime_start" -gt 0 ] && [ "$start_line" -lt "$runtime_start" ]; then
    start_line="$runtime_start"
  fi

  if [ "$total_lines" -ge "$start_line" ]; then
    xmj_launch_print_log_lines "$start_line" "$total_lines" "$file"
  elif [ "$runtime_start" -gt 0 ]; then
    printf '  %b酒馆已经在运行，等待新的后台输出。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  else
    printf '  %b日志还没有输出，新的后台日志会实时追加在这里。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  fi

  XMJ_LAUNCH_LOG_CURSOR="$total_lines"
}

xmj_launch_render_boot_log_snapshot() {
  local snapshot_size="${1:-18}"
  local file=''
  local total_lines='0'
  local start_line='1'
  local end_line='0'
  local runtime_start="${XMJ_LAUNCH_RUNTIME_LOG_START:-0}"

  file="$(xmj_launch_display_log_file)"
  total_lines="$(xmj_launch_log_line_count "$file")"
  if [ "$snapshot_size" -lt 1 ]; then
    snapshot_size='18'
  fi

  case "$runtime_start" in
    ''|*[!0-9]*)
      runtime_start='0'
      ;;
  esac

  if [ "$runtime_start" -gt 1 ]; then
    end_line=$((runtime_start - 1))
  else
    end_line="$total_lines"
  fi

  if [ "$end_line" -lt 1 ]; then
    printf '  %b启动日志还没有输出，新的后台日志会追加在这里。%b\n' "$XMJ_MIST" "$XMJ_RESET"
    XMJ_LAUNCH_LOG_CURSOR='0'
    return 0
  fi

  if [ "$end_line" -gt "$snapshot_size" ]; then
    start_line=$((end_line - snapshot_size + 1))
  fi

  xmj_launch_print_log_lines "$start_line" "$end_line" "$file"
  XMJ_LAUNCH_LOG_CURSOR="$end_line"
}

xmj_launch_print_new_log_lines() {
  local file=''
  local total_lines='0'
  local start_line='1'
  local cursor="${XMJ_LAUNCH_LOG_CURSOR:-0}"
  local runtime_start="${XMJ_LAUNCH_RUNTIME_LOG_START:-0}"

  file="$(xmj_launch_display_log_file)"
  total_lines="$(xmj_launch_log_line_count "$file")"

  case "$runtime_start" in
    ''|*[!0-9]*)
      runtime_start='0'
      ;;
  esac
  if [ "$runtime_start" -gt 0 ] && [ "$cursor" -lt $((runtime_start - 1)) ]; then
    cursor=$((runtime_start - 1))
  fi

  if [ "$total_lines" -lt "$cursor" ]; then
    cursor='0'
  fi

  if [ "$total_lines" -le "$cursor" ]; then
    XMJ_LAUNCH_LOG_CURSOR="$total_lines"
    return 0
  fi

  start_line=$((cursor + 1))
  xmj_launch_print_log_lines "$start_line" "$total_lines" "$file"
  XMJ_LAUNCH_LOG_CURSOR="$total_lines"
}

xmj_launch_wait_for_running() {
  local step='0'
  local wait_limit=''
  local slow_notice_at=''
  local slow_notice_shown='0'
  local probe_fallback_at='0'
  local should_probe='0'
  local candidate_url=''
  local detected_url=''
  local logged_probe_urls='|'

  wait_limit="$(xmj_launch_wait_limit_seconds)"
  case "$wait_limit" in
    ''|*[!0-9]*)
      wait_limit='300'
      ;;
  esac

  slow_notice_at="$(xmj_launch_slow_notice_seconds)"
  case "$slow_notice_at" in
    ''|*[!0-9]*)
      slow_notice_at='150'
      ;;
  esac

  if [ "$slow_notice_at" -ge "$wait_limit" ]; then
    slow_notice_at='0'
  fi

  probe_fallback_at="$(xmj_launch_probe_fallback_seconds)"
  case "$probe_fallback_at" in
    ''|*[!0-9]*)
      probe_fallback_at='240'
      ;;
  esac
  if [ "$probe_fallback_at" -ge "$wait_limit" ]; then
    probe_fallback_at=$((wait_limit - 1))
  fi

  XMJ_LAUNCH_ENTRY_URL="$(xmj_launch_entry_url)"
  if xmj_launch_can_probe_url; then
    should_probe='1'
    while IFS= read -r candidate_url || [ -n "$candidate_url" ]; do
      if [ -z "$candidate_url" ]; then
        continue
      fi

      case "$logged_probe_urls" in
        *"|$candidate_url|"*)
          continue
          ;;
      esac

      if [ "$logged_probe_urls" = '|' ]; then
        xmj_launch_log_line "准备检测酒馆入口：${candidate_url}"
      else
        xmj_launch_log_line "补充检测入口：${candidate_url}"
      fi

      logged_probe_urls="${logged_probe_urls}${candidate_url}|"
    done < <(xmj_launch_probe_candidate_urls)
  else
    xmj_launch_log_line '当前环境未检测到 curl 或 wget，将按进程存活判定启动完成。'
  fi

  for ((step = 1; step <= wait_limit; step += 1)); do
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    if [ "$slow_notice_at" -gt 0 ] && [ "$slow_notice_shown" != '1' ] && [ "$step" -ge "$slow_notice_at" ]; then
      slow_notice_shown='1'
      xmj_launch_log_line "启动等待已超过 ${slow_notice_at} 秒，继续等待直到 ${wait_limit} 秒。"
      xmj_render_launch_progress \
        'boot' \
        '启动较久' \
        "这次启动已经超过 ${slow_notice_at} 秒，可能还在编译前端或整理插件；猫猫会继续等到 ${wait_limit} 秒。"
    fi

    if ! xmj_launch_process_alive; then
      xmj_launch_wait_process >/dev/null
      xmj_launch_fail 'boot' '启动失败' '酒馆没有顺利进入运行状态，可温和查看日志。'
      return 1
    fi

    detected_url="$(xmj_launch_detect_ready_entry_url || true)"
    if [ -n "$detected_url" ]; then
      if [ "$detected_url" != "${XMJ_LAUNCH_ENTRY_URL:-}" ]; then
        xmj_launch_log_line "已从后台日志识别到入口：${detected_url}"
      fi
      XMJ_LAUNCH_ENTRY_URL="$detected_url"
      if ! xmj_launch_confirm_ready_state "$XMJ_LAUNCH_ENTRY_URL"; then
        if ! xmj_launch_process_alive; then
          xmj_launch_wait_process >/dev/null
          xmj_launch_fail 'boot' '启动失败' '酒馆在显示 Go to 后又很快退出了，可以温和查看日志。'
          return 1
        fi
        continue
      fi
      xmj_launch_log_line '后台日志已显示酒馆入口，按日志判定进入运行阶段。'
      xmj_launch_mark_runtime_log_start
      return 0
    fi

    if [ "$should_probe" = '1' ] && [ "$step" -ge "$probe_fallback_at" ]; then
      while IFS= read -r candidate_url || [ -n "$candidate_url" ]; do
        if [ -z "$candidate_url" ]; then
          continue
        fi

        case "$logged_probe_urls" in
          *"|$candidate_url|"*)
            ;;
          *)
            xmj_launch_log_line "补充检测入口：${candidate_url}"
            logged_probe_urls="${logged_probe_urls}${candidate_url}|"
            ;;
        esac

        if xmj_launch_endpoint_available "$candidate_url"; then
          XMJ_LAUNCH_ENTRY_URL="$candidate_url"
          xmj_launch_log_line "酒馆入口已可访问：${XMJ_LAUNCH_ENTRY_URL}"
          xmj_launch_log_line '后台日志暂未出现 Go to，已按入口可访问判定进入运行阶段。'
          xmj_launch_mark_runtime_log_start
          return 0
        fi
      done < <(xmj_launch_probe_candidate_urls)
    elif [ "$step" -ge 2 ]; then
      xmj_launch_log_line '已按后台进程存活判定进入运行阶段。'
      xmj_launch_log_line "进入链接：${XMJ_LAUNCH_ENTRY_URL}"
      xmj_launch_mark_runtime_log_start
      return 0
    fi

    xmj_launch_print_new_log_lines

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
  xmj_launch_mark_runtime_log_start
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
  if [ "${XMJ_LAUNCH_LOG_VIEW_STARTED:-0}" != '1' ]; then
    xmj_render_launch_running_screen
    xmj_launch_render_boot_log_snapshot '18'
    if xmj_launch_runtime_stream_enabled; then
      xmj_launch_enable_frontend_stream_output
    else
      xmj_launch_print_new_log_lines
    fi
    XMJ_LAUNCH_LOG_VIEW_STARTED='1'
  fi

  while true; do
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    if ! xmj_launch_process_alive; then
      if xmj_launch_runtime_stream_enabled; then
        xmj_launch_flush_pending_runtime_output
      else
        xmj_launch_print_new_log_lines
      fi
      return 0
    fi

    sleep 1 || true

    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      return 130
    fi

    if xmj_launch_runtime_stream_enabled; then
      xmj_launch_flush_pending_runtime_output
    else
      xmj_launch_print_new_log_lines
    fi
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

xmj_launch_monitor_attached_session() {
  while true; do
    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      xmj_launch_handle_interrupt
      return 0
    fi

    if ! xmj_launch_session_running; then
      xmj_launch_print_new_log_lines
      XMJ_LAUNCH_EXIT_CODE='0'
      XMJ_LAUNCH_WAITED='1'
      xmj_render_backend_display_screen 'stopped'
      xmj_launch_render_log_snapshot '18'
      xmj_render_page_footer '按回车返回首页'
      return 0
    fi

    sleep 1 || true

    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      xmj_launch_handle_interrupt
      return 0
    fi

    xmj_launch_print_new_log_lines
  done
}

xmj_run_backend_display_page() {
  xmj_launch_reset_state

  if ! xmj_launch_attach_latest_session; then
    xmj_render_backend_display_screen 'empty'
    xmj_render_page_footer '按回车返回首页'
    return 0
  fi

  if xmj_launch_session_running; then
    xmj_launch_install_int_trap
    xmj_render_backend_display_screen 'running'
    xmj_launch_render_log_snapshot '18'
    XMJ_LAUNCH_LOG_VIEW_STARTED='1'
    XMJ_LAUNCH_RUNNING_NOTICE_SHOWN='1'
    xmj_launch_monitor_attached_session
    xmj_launch_restore_int_trap
    return 0
  fi

  xmj_render_backend_display_screen 'stopped'
  xmj_launch_render_log_snapshot '18'
  xmj_render_page_footer '按回车返回首页'
  return 0
}

xmj_run_tavern_launch() {
  local boot_detail='(,,>ヮ<,,)! 小猫正在把酒馆悄悄放到后台运行喵~'

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

  while true; do
    xmj_render_launch_progress \
      'boot' \
      '启动中' \
      "$boot_detail"
    XMJ_LAUNCH_LOG_VIEW_STARTED='0'
    XMJ_LAUNCH_RUNNING_NOTICE_SHOWN='0'

    if ! xmj_launch_start_process; then
      xmj_launch_restore_int_trap
      xmj_render_launch_result \
        'failure' \
        "$XMJ_LAUNCH_STAGE" \
        "$XMJ_LAUNCH_SUMMARY" \
        "$XMJ_LAUNCH_DETAIL"
      return 0
    fi

    if xmj_launch_wait_for_running; then
      break
    fi

    if [ "${XMJ_LAUNCH_INTERRUPT:-0}" = '1' ]; then
      xmj_launch_handle_interrupt
      xmj_launch_restore_int_trap
      return 0
    fi

    if xmj_launch_try_start_sh_fallback; then
      boot_detail='(,,>ヮ<,,)! 直启主入口这次没顺利跑起来，猫猫已经自动切回 start.sh 再试一次喵~'
      continue
    fi

    if xmj_launch_try_recover_dependency_import_assertion_failure; then
      boot_detail='(,,>ヮ<,,)! 检测到依赖里旧 JSON 导入语法，已经自动修好，准备重试启动喵~'
      continue
    fi

    xmj_launch_restore_int_trap
    xmj_render_launch_result \
      'failure' \
      "$XMJ_LAUNCH_STAGE" \
      "$XMJ_LAUNCH_SUMMARY" \
      "$XMJ_LAUNCH_DETAIL"
    return 0
  done

  xmj_launch_monitor_running
  xmj_launch_restore_int_trap
  return 0
}
