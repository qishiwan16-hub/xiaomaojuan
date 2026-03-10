xmj_maintenance_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y%m%d_%H%M' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown_time'
  fi

  printf '%s' "$timestamp"
}

xmj_maintenance_log() {
  local logger_name="${1:-}"
  local message="${2:-}"

  if [ -z "$logger_name" ] || [ -z "$message" ]; then
    return 0
  fi

  if declare -F "$logger_name" >/dev/null 2>&1; then
    "$logger_name" "$message"
  fi
}

xmj_maintenance_shell_log_target() {
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
    return 0
  fi

  printf '%s' '/dev/null'
}

xmj_maintenance_backup_dir() {
  if [ -n "${XMJ_BACKUP_DIR:-}" ]; then
    printf '%s' "$XMJ_BACKUP_DIR"
    return 0
  fi

  printf '%s/备份' "${XMJ_ROOT_DIR:-.}"
}

xmj_maintenance_history_file() {
  printf '%s/更新记录.log' "${XMJ_ROOT_DIR:-.}"
}

xmj_maintenance_clear_state() {
  XMJ_MAINT_BACKUP_DIR=''
  XMJ_MAINT_BACKUP_FILE=''
  XMJ_MAINT_BACKUP_NAME=''
  XMJ_MAINT_BACKUP_NOTE=''
  XMJ_MAINT_BACKUP_RESTORE_NOTE=''
  XMJ_MAINT_BACKUP_ITEMS=''
  XMJ_MAINT_BACKUP_MISSING_ITEMS=''
  XMJ_MAINT_BACKUP_SCOPE='full'
  XMJ_MAINT_BACKUP_COMPAT_MODE='0'
  XMJ_MAINT_BACKUP_COMPAT_NOTE=''
  XMJ_MAINT_HISTORY_FILE=''
  XMJ_MAINT_LAST_ERROR=''
}

xmj_maintenance_join_labels() {
  local joined=''
  local item=''

  for item in "$@"; do
    if [ -z "$item" ]; then
      continue
    fi

    if [ -n "$joined" ]; then
      joined="${joined}、"
    fi
    joined="${joined}${item}"
  done

  printf '%s' "$joined"
}

xmj_maintenance_backup_label() {
  case "${1:-}" in
    data)
      printf '%s' 'data 文件夹'
      ;;
    public/scripts/extensions/third-party)
      printf '%s' 'third-party 扩展目录'
      ;;
    config.yaml)
      printf '%s' 'config.yaml'
      ;;
    *)
      printf '%s' "${1:-未知内容}"
      ;;
  esac
}

xmj_maintenance_compat_floor_version() {
  printf '%s' '1.13.4'
}

xmj_maintenance_tavern_setting_hint() {
  printf '%s' '更新维护里的 02 一键更新 / 03 版本切换'
}

xmj_maintenance_extract_semver() {
  local raw_text="${1:-}"

  if [[ "$raw_text" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    printf '%s.%s.%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    return 0
  fi

  printf '%s' ''
  return 1
}

xmj_maintenance_version_lt() {
  local left_text="${1:-}"
  local right_text="${2:-}"
  local left_version=''
  local right_version=''
  local left_major='0'
  local left_minor='0'
  local left_patch='0'
  local right_major='0'
  local right_minor='0'
  local right_patch='0'

  left_version="$(xmj_maintenance_extract_semver "$left_text")"
  right_version="$(xmj_maintenance_extract_semver "$right_text")"

  if [ -z "$left_version" ] || [ -z "$right_version" ]; then
    return 1
  fi

  IFS='.' read -r left_major left_minor left_patch <<EOF
$left_version
EOF
  IFS='.' read -r right_major right_minor right_patch <<EOF
$right_version
EOF

  if [ $((10#$left_major)) -lt $((10#$right_major)) ]; then
    return 0
  fi
  if [ $((10#$left_major)) -gt $((10#$right_major)) ]; then
    return 1
  fi

  if [ $((10#$left_minor)) -lt $((10#$right_minor)) ]; then
    return 0
  fi
  if [ $((10#$left_minor)) -gt $((10#$right_minor)) ]; then
    return 1
  fi

  [ $((10#$left_patch)) -lt $((10#$right_patch)) ]
}

xmj_maintenance_data_only_backup_reason() {
  local current_version="${1:-}"
  local target_version="${2:-}"
  local compat_floor=''
  local current_is_old='0'
  local target_is_old='0'

  compat_floor="$(xmj_maintenance_compat_floor_version)"

  if xmj_maintenance_version_lt "$current_version" "$compat_floor"; then
    current_is_old='1'
  fi

  if xmj_maintenance_version_lt "$target_version" "$compat_floor"; then
    target_is_old='1'
  fi

  case "${current_is_old}:${target_is_old}" in
    1:1)
      printf '%s' "当前酒馆版本和目标版本都低于 ${compat_floor}"
      ;;
    1:0)
      printf '%s' "当前酒馆版本低于 ${compat_floor}"
      ;;
    0:1)
      printf '%s' "目标版本低于 ${compat_floor}"
      ;;
    *)
      printf '%s' ''
      ;;
  esac
}

xmj_maintenance_should_backup_data_only() {
  [ -n "$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")" ]
}

xmj_maintenance_cross_version_notice() {
  printf '%s' '因为跨版本兼容，部分装在多用户上的插件可能要重新安装，酒馆设置也要重新确认。'
}

xmj_maintenance_backup_scope_text() {
  if xmj_maintenance_should_backup_data_only "${1:-}" "${2:-}"; then
    printf '%s' 'data 文件夹'
    return 0
  fi

  printf '%s' 'data / third-party / config.yaml'
}

xmj_maintenance_backup_stage_text() {
  local reason_text=''

  reason_text="$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")"
  if [ -n "$reason_text" ]; then
    printf '%s' "${reason_text}，这次只先收好 data 文件夹。"
    return 0
  fi

  printf '%s' '正在把 data、third-party 和 config.yaml 打成 1 个备份压缩包。'
}

xmj_maintenance_backup_preview_note() {
  local reason_text=''

  reason_text="$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")"
  if [ -n "$reason_text" ]; then
    printf '%s' "${reason_text}，猫猫这次只会收好 data 文件夹。$(xmj_maintenance_cross_version_notice)"
    return 0
  fi

  printf '%s' '会把 data、third-party 和 config.yaml 一起收进 1 个备份压缩包。'
}

xmj_maintenance_backup_meta_name() {
  printf '%s' '.xmj-backup-meta'
}

xmj_maintenance_write_backup_meta() {
  local bundle_root="${1:-}"
  local meta_file=''

  if [ -z "$bundle_root" ] || [ ! -d "$bundle_root" ]; then
    return 1
  fi

  meta_file="$bundle_root/$(xmj_maintenance_backup_meta_name)"
  {
    printf 'scope=%s\n' "${XMJ_MAINT_BACKUP_SCOPE:-full}"
    printf 'compat_mode=%s\n' "${XMJ_MAINT_BACKUP_COMPAT_MODE:-0}"
  } > "$meta_file"
}

xmj_maintenance_load_backup_meta() {
  local bundle_root="${1:-}"
  local meta_file=''
  local key=''
  local value=''

  meta_file="$bundle_root/$(xmj_maintenance_backup_meta_name)"
  if [ ! -f "$meta_file" ]; then
    return 1
  fi

  while IFS='=' read -r key value; do
    case "$key" in
      scope)
        XMJ_MAINT_BACKUP_SCOPE="${value:-full}"
        ;;
      compat_mode)
        XMJ_MAINT_BACKUP_COMPAT_MODE="${value:-0}"
        ;;
    esac
  done < "$meta_file"

  if [ "${XMJ_MAINT_BACKUP_COMPAT_MODE:-0}" = '1' ]; then
    XMJ_MAINT_BACKUP_COMPAT_NOTE="$(xmj_maintenance_cross_version_notice)"
  else
    XMJ_MAINT_BACKUP_COMPAT_NOTE=''
  fi

  return 0
}

xmj_maintenance_require_archive_tools() {
  if ! command -v zip >/dev/null 2>&1; then
    XMJ_MAINT_LAST_ERROR='未检测到 zip，请先在 Termux 中安装 zip。'
    return 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    XMJ_MAINT_LAST_ERROR='未检测到 unzip，请先在 Termux 中安装 unzip。'
    return 1
  fi

  return 0
}

xmj_maintenance_repo_version() {
  local repo_path="${1:-}"
  local log_file="${2:-}"
  local shell_log='/dev/null'
  local exact_tag=''
  local describe_name=''
  local commit_name=''

  if [ -n "$log_file" ]; then
    shell_log="$log_file"
  fi

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    printf '%s' '未知'
    return 0
  fi

  exact_tag="$(git -C "$repo_path" describe --tags --exact-match 2>>"$shell_log" || true)"
  if [ -n "$exact_tag" ]; then
    printf '%s' "$exact_tag"
    return 0
  fi

  describe_name="$(git -C "$repo_path" describe --tags --always --dirty 2>>"$shell_log" || true)"
  if [ -n "$describe_name" ]; then
    printf '%s' "$describe_name"
    return 0
  fi

  commit_name="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$shell_log" || true)"
  if [ -n "$commit_name" ]; then
    printf '%s' "$commit_name"
    return 0
  fi

  printf '%s' '未知'
}

xmj_maintenance_classify_change() {
  local repo_path="${1:-}"
  local before_commit="${2:-}"
  local after_commit="${3:-}"
  local log_file="${4:-}"
  local shell_log='/dev/null'
  local before_ts='0'
  local after_ts='0'

  if [ -n "$log_file" ]; then
    shell_log="$log_file"
  fi

  if [ -z "$repo_path" ] || [ -z "$before_commit" ] || [ -z "$after_commit" ] || [ "$before_commit" = "$after_commit" ]; then
    printf '%s' ''
    return 0
  fi

  if git -C "$repo_path" merge-base --is-ancestor "$before_commit" "$after_commit" 2>>"$shell_log"; then
    printf '%s' '更新'
    return 0
  fi

  if git -C "$repo_path" merge-base --is-ancestor "$after_commit" "$before_commit" 2>>"$shell_log"; then
    printf '%s' '回退'
    return 0
  fi

  before_ts="$(git -C "$repo_path" show -s --format=%ct "$before_commit" 2>>"$shell_log" || true)"
  after_ts="$(git -C "$repo_path" show -s --format=%ct "$after_commit" 2>>"$shell_log" || true)"

  case "$before_ts" in
    ''|*[!0-9]*)
      before_ts='0'
      ;;
  esac

  case "$after_ts" in
    ''|*[!0-9]*)
      after_ts='0'
      ;;
  esac

  if [ "$after_ts" -lt "$before_ts" ]; then
    printf '%s' '回退'
    return 0
  fi

  printf '%s' '更新'
}

xmj_maintenance_create_backup() {
  local repo_path="${1:-}"
  local logger_name="${2:-}"
  local log_file="${3:-}"
  local op_name="${4:-维护}"
  local shell_log='/dev/null'
  local backup_dir=''
  local archive_name=''
  local archive_file=''
  local item=''
  local item_label=''
  local joined_items=''
  local joined_missing=''
  local -a items=()
  local -a item_labels=()
  local -a missing_labels=()

  xmj_maintenance_clear_state

  if [ -n "$log_file" ]; then
    shell_log="$log_file"
  fi

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    XMJ_MAINT_LAST_ERROR='未找到可备份的酒馆目录。'
    return 1
  fi

  if ! xmj_maintenance_require_archive_tools; then
    return 1
  fi

  for item in 'data' 'public/scripts/extensions/third-party' 'config.yaml'; do
    if [ -d "$repo_path/$item" ] || [ -f "$repo_path/$item" ]; then
      items+=("$item")
      item_labels+=("$(xmj_maintenance_backup_label "$item")")
    else
      missing_labels+=("$(xmj_maintenance_backup_label "$item")")
    fi
  done

  if [ "${#items[@]}" -eq 0 ]; then
    XMJ_MAINT_LAST_ERROR='未找到可备份内容，至少需要 data、third-party 或 config.yaml 之一存在。'
    return 1
  fi

  backup_dir="$(xmj_maintenance_backup_dir)"
  if ! mkdir -p "$backup_dir" 2>/dev/null; then
    XMJ_MAINT_LAST_ERROR="无法创建备份目录：$backup_dir"
    return 1
  fi

  archive_name="$(xmj_maintenance_timestamp).zip"
  archive_file="$backup_dir/$archive_name"
  rm -f "$archive_file" 2>/dev/null || true

  xmj_maintenance_log "$logger_name" "开始为${op_name}自动备份数据。"
  xmj_maintenance_log "$logger_name" "备份目标：$(xmj_display_path "$archive_file")"

  if ! (
    cd "$repo_path" || exit 1
    zip -rq "$archive_file" "${items[@]}"
  ) >>"$shell_log" 2>&1; then
    XMJ_MAINT_LAST_ERROR='生成 zip 备份失败，可温和查看日志。'
    return 1
  fi

  joined_items="$(xmj_maintenance_join_labels "${item_labels[@]}")"
  joined_missing="$(xmj_maintenance_join_labels "${missing_labels[@]}")"

  XMJ_MAINT_BACKUP_DIR="$backup_dir"
  XMJ_MAINT_BACKUP_FILE="$archive_file"
  XMJ_MAINT_BACKUP_NAME="$archive_name"
  XMJ_MAINT_BACKUP_ITEMS="$joined_items"
  XMJ_MAINT_BACKUP_MISSING_ITEMS="$joined_missing"
  XMJ_MAINT_BACKUP_NOTE="已自动备份 ${joined_items}。"

  if [ -n "$joined_missing" ]; then
    XMJ_MAINT_BACKUP_NOTE="${XMJ_MAINT_BACKUP_NOTE} 本次未发现 ${joined_missing}，压缩包只包含已有内容。"
  fi

  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
  return 0
}

xmj_maintenance_restore_backup() {
  local repo_path="${1:-}"
  local logger_name="${2:-}"
  local log_file="${3:-}"
  local shell_log='/dev/null'

  if [ -n "$log_file" ]; then
    shell_log="$log_file"
  fi

  if [ -z "${XMJ_MAINT_BACKUP_FILE:-}" ] || [ ! -f "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
    XMJ_MAINT_LAST_ERROR='没有找到可恢复的备份压缩包。'
    return 1
  fi

  if ! xmj_maintenance_require_archive_tools; then
    return 1
  fi

  if [ -z "$repo_path" ]; then
    XMJ_MAINT_LAST_ERROR='恢复目标目录为空。'
    return 1
  fi

  if ! mkdir -p "$repo_path" 2>/dev/null; then
    XMJ_MAINT_LAST_ERROR="无法准备恢复目录：$repo_path"
    return 1
  fi

  xmj_maintenance_log "$logger_name" "开始从备份压缩包恢复：$(xmj_display_path "$XMJ_MAINT_BACKUP_FILE")"

  if ! unzip -oq "$XMJ_MAINT_BACKUP_FILE" -d "$repo_path" >>"$shell_log" 2>&1; then
    XMJ_MAINT_LAST_ERROR='解压备份压缩包失败，可温和查看日志。'
    return 1
  fi

  XMJ_MAINT_BACKUP_RESTORE_NOTE='已覆盖恢复备份内容。'
  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  return 0
}

xmj_maintenance_ensure_history_file() {
  local history_file=''

  history_file="$(xmj_maintenance_history_file)"
  if [ -z "$history_file" ]; then
    XMJ_MAINT_LAST_ERROR='无法定位更新记录文件。'
    return 1
  fi

  if [ ! -f "$history_file" ]; then
    if ! : >"$history_file" 2>/dev/null; then
      XMJ_MAINT_LAST_ERROR="无法创建更新记录文件：$history_file"
      return 1
    fi
  fi

  XMJ_MAINT_HISTORY_FILE="$history_file"

  if [ ! -s "$history_file" ]; then
    {
      printf '小猫卷更新记录\n'
      printf '时间 | 操作 | 当前版本 | 说明\n'
      printf '----------------------------------------\n'
    } >>"$history_file"
  fi

  return 0
}

xmj_maintenance_record_history() {
  local action_kind="${1:-}"
  local current_version="${2:-未知}"
  local note_text="${3:-}"
  local logger_name="${4:-}"
  local history_file=''
  local timestamp=''

  if [ -z "$action_kind" ]; then
    XMJ_MAINT_LAST_ERROR='更新记录缺少操作类型。'
    return 1
  fi

  if ! xmj_maintenance_ensure_history_file; then
    return 1
  fi

  history_file="$XMJ_MAINT_HISTORY_FILE"
  timestamp="$(xmj_maintenance_timestamp)"

  if [ -z "$note_text" ]; then
    note_text='-'
  fi

  if ! printf '%s | %s | %s | %s\n' "$timestamp" "$action_kind" "$current_version" "$note_text" >>"$history_file"; then
    XMJ_MAINT_LAST_ERROR='写入更新记录失败。'
    return 1
  fi

  xmj_maintenance_log "$logger_name" "已写入更新记录：$timestamp | $action_kind | $current_version"
  return 0
}

xmj_reinstall_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown-time'
  fi

  printf '%s' "$timestamp"
}

xmj_reinstall_reset_state() {
  XMJ_REINSTALL_LOG_FILE=''
  XMJ_REINSTALL_STAGE='prepare'
  XMJ_REINSTALL_SUMMARY=''
  XMJ_REINSTALL_DETAIL=''
  XMJ_REINSTALL_REPO_URL=''
  XMJ_REINSTALL_BRANCH='release'
  XMJ_REINSTALL_TARGET_DIR=''
  XMJ_REINSTALL_BEFORE_VERSION='未知'
  XMJ_REINSTALL_AFTER_VERSION='未知'
  XMJ_REINSTALL_AFTER_COMMIT=''
  XMJ_REINSTALL_BACKUP_FILE=''
  XMJ_REINSTALL_BACKUP_NOTE=''
  XMJ_REINSTALL_RESTORE_NOTE=''
}

xmj_reinstall_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_REINSTALL_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_reinstall_timestamp)" "$line" >>"$XMJ_REINSTALL_LOG_FILE"
}

xmj_reinstall_prepare_log_file() {
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

  XMJ_REINSTALL_LOG_FILE="$XMJ_LOG_DIR/reinstall-$stamp.log"
  if ! : >"$XMJ_REINSTALL_LOG_FILE" 2>/dev/null; then
    return 1
  fi

  xmj_reinstall_log_line '小猫卷卸载重装日志已创建。'
  xmj_reinstall_log_line "目标目录：${XMJ_SILLYTAVERN_PATH:-未设置}"
  return 0
}

xmj_reinstall_fail() {
  local stage="${1:-env}"
  local summary="${2:-卸载重装失败}"
  local detail="${3:-请温和查看日志。}"

  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    detail="$(xmj_reinstall_append_detail "$detail" "$XMJ_MAINT_BACKUP_COMPAT_NOTE")"
  fi

  XMJ_REINSTALL_STAGE="$stage"
  XMJ_REINSTALL_SUMMARY="$summary"
  XMJ_REINSTALL_DETAIL="$detail"

  xmj_reinstall_log_line "失败阶段：$stage"
  xmj_reinstall_log_line "失败摘要：$summary"
  xmj_reinstall_log_line "失败说明：$detail"
  return 1
}

xmj_reinstall_assert_safe_target() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local parent_dir=''
  local base_name=''

  if [ -z "$repo_path" ]; then
    xmj_reinstall_fail 'env' '未设置酒馆路径' '请先在配置里填写 SillyTavern 目录。'
    return 1
  fi

  case "$repo_path" in
    ''|'/'|'.'|'..')
      xmj_reinstall_fail 'env' '酒馆路径不安全' '当前路径过于危险，已阻止卸载重装。'
      return 1
      ;;
  esac

  if [ "$repo_path" = "${HOME:-/nonexistent}" ] || [ "$repo_path" = "${XMJ_ROOT_DIR:-/nonexistent}" ]; then
    xmj_reinstall_fail 'env' '酒馆路径不安全' '当前路径过于危险，已阻止卸载重装。'
    return 1
  fi

  parent_dir="$(dirname "$repo_path")"
  base_name="$(basename "$repo_path")"

  if [ -z "$base_name" ] || [ "$base_name" = '.' ] || [ "$base_name" = '..' ] || [ "$parent_dir" = "$repo_path" ]; then
    xmj_reinstall_fail 'env' '酒馆路径不安全' '当前路径过于危险，已阻止卸载重装。'
    return 1
  fi

  if [ ! -d "$parent_dir" ] && ! mkdir -p "$parent_dir" 2>/dev/null; then
    xmj_reinstall_fail 'env' '无法准备安装目录' '酒馆父目录不存在，且没有顺利创建。'
    return 1
  fi

  XMJ_REINSTALL_TARGET_DIR="$repo_path"
  return 0
}

xmj_reinstall_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local shell_log='/dev/null'

  if ! xmj_reinstall_assert_safe_target; then
    return 1
  fi

  if [ -n "${XMJ_REINSTALL_LOG_FILE:-}" ]; then
    shell_log="$XMJ_REINSTALL_LOG_FILE"
  fi

  if [ ! -d "$repo_path" ]; then
    xmj_reinstall_fail 'env' '未找到现有酒馆目录' '04 适用于已有酒馆目录的卸载重装，请先确认路径是否正确。'
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    xmj_reinstall_fail 'env' '未检测到 Git' '请先在 Termux 中安装 git 后再试。'
    return 1
  fi

  XMJ_REINSTALL_BEFORE_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$shell_log")"

  XMJ_REINSTALL_REPO_URL="$(git -C "$repo_path" remote get-url origin 2>>"$shell_log" || true)"
  if [ -z "$XMJ_REINSTALL_REPO_URL" ]; then
    XMJ_REINSTALL_REPO_URL='https://github.com/SillyTavern/SillyTavern.git'
    xmj_reinstall_log_line "未读取到 origin，已回退到默认仓库：$XMJ_REINSTALL_REPO_URL"
  fi

  XMJ_REINSTALL_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$shell_log" || true)"
  if [ -z "$XMJ_REINSTALL_BRANCH" ]; then
    XMJ_REINSTALL_BRANCH='release'
  fi

  xmj_reinstall_log_line "当前版本：${XMJ_REINSTALL_BEFORE_VERSION}"
  xmj_reinstall_log_line "重装来源：${XMJ_REINSTALL_REPO_URL}"
  xmj_reinstall_log_line "目标分支：${XMJ_REINSTALL_BRANCH}"
  return 0
}

xmj_render_reinstall_confirm_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_identity '04' "${XMJ_MENU_LABEL['04']}"
  printf '\n'
  xmj_render_page_intro \
    '卸载重装会先自动打包备份，再移除旧目录并重新安装。' \
    '完成后会把 data、third-party 和 config.yaml 覆盖恢复回来。'
  printf '\n'
  xmj_render_setting_card \
    '即将开始卸载重装' \
    "当前版本：${XMJ_REINSTALL_BEFORE_VERSION}" \
    "默认会重装到分支：${XMJ_REINSTALL_BRANCH}。"
  printf '\n'
  xmj_render_fact_line '酒馆目录' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_fact_line '仓库来源' "${XMJ_REINSTALL_REPO_URL:-未知}"
  printf '\n'
  printf '  %b♡ 风险提醒%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '  %b• 会删除当前酒馆目录后再重新安装。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b• 在删除前会自动生成 zip 备份，并保存在脚本目录下的备份文件夹。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  printf '  %b输入 y 开始卸载重装；输入其它任意内容取消并返回首页。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_reinstall_prompt_confirm_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  开始卸载重装（y / 其它取消）> ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_reinstall_remove_old_dir() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ ! -d "$repo_path" ]; then
    return 0
  fi

  xmj_reinstall_log_line "准备删除旧目录：$repo_path"
  if ! rm -rf "$repo_path" >>"$XMJ_REINSTALL_LOG_FILE" 2>&1; then
    xmj_reinstall_fail 'remove' '删除旧目录失败' '旧酒馆目录没有顺利移除，可温和查看日志。'
    return 1
  fi

  xmj_reinstall_log_line '旧目录已移除。'
  return 0
}

xmj_reinstall_clone_repo() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  xmj_reinstall_log_line "开始重新安装：${XMJ_REINSTALL_REPO_URL} @ ${XMJ_REINSTALL_BRANCH}"

  if git clone --single-branch --branch "$XMJ_REINSTALL_BRANCH" "$XMJ_REINSTALL_REPO_URL" "$repo_path" >>"$XMJ_REINSTALL_LOG_FILE" 2>&1; then
    xmj_reinstall_log_line '已按目标分支完成克隆。'
    return 0
  fi

  xmj_reinstall_log_line '按目标分支克隆失败，尝试回退到仓库默认分支。'
  if ! git clone "$XMJ_REINSTALL_REPO_URL" "$repo_path" >>"$XMJ_REINSTALL_LOG_FILE" 2>&1; then
    xmj_reinstall_fail 'install' '重新安装失败' 'Git clone 没有顺利完成，可温和查看日志。'
    return 1
  fi

  XMJ_REINSTALL_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_REINSTALL_LOG_FILE" || printf '%s' "${XMJ_REINSTALL_BRANCH:-release}")"
  xmj_reinstall_log_line '已按仓库默认分支完成克隆。'
  return 0
}

xmj_reinstall_sync_dependencies() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ ! -f "$repo_path/package.json" ]; then
    xmj_reinstall_log_line '未发现 package.json，已跳过依赖同步。'
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    xmj_reinstall_fail 'deps' '未检测到 npm' '代码已重新安装，但当前环境无法完成依赖整理。'
    return 1
  fi

  if ! (
    cd "$repo_path" || exit 1
    npm install --no-audit --no-fund
  ) >>"$XMJ_REINSTALL_LOG_FILE" 2>&1; then
    xmj_reinstall_fail 'deps' '同步依赖失败' '依赖整理没有顺利完成，可温和查看日志。'
    return 1
  fi

  xmj_reinstall_log_line '依赖同步已完成。'
  return 0
}

xmj_run_update_history_page() {
  local history_file=''
  local total_lines='0'
  local start_line='1'
  local display_lines='18'
  local line=''

  history_file="$(xmj_maintenance_history_file)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_identity '05' "${XMJ_MENU_LABEL['05']}"
  printf '\n'
  xmj_render_page_intro \
    '这里会收纳更新、回退和卸载相关的历史记录。' \
    '默认展示最近几条，方便你快速核对最近一次维护动作。'
  printf '\n'
  xmj_render_fact_line '记录文件' "$(xmj_display_path "$history_file")"

  if [ ! -f "$history_file" ] || [ ! -s "$history_file" ]; then
    printf '\n'
    xmj_render_setting_card '还没有历史记录' '当前还没有写入任何更新、回退或卸载条目。' '等你执行真实维护操作后，这里会自动出现记录。'
    xmj_render_page_footer '按回车返回首页'
    return 0
  fi

  total_lines="$(wc -l <"$history_file" 2>/dev/null || true)"
  total_lines="${total_lines//[[:space:]]/}"
  case "$total_lines" in
    ''|*[!0-9]*)
      total_lines='0'
      ;;
  esac

  if [ "$total_lines" -gt "$display_lines" ]; then
    start_line=$((total_lines - display_lines + 1))
  fi

  printf '\n'
  printf '  %b♡ 最近记录%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  while IFS= read -r line || [ -n "$line" ]; do
    printf '  %b%s%b\n' "$XMJ_WHITE" "$line" "$XMJ_RESET"
  done < <(sed -n "${start_line},${total_lines}p" "$history_file" 2>/dev/null)

  xmj_render_page_footer '按回车返回首页'
}

xmj_run_tavern_reinstall() {
  local input=''
  local history_note=''

  xmj_reinstall_reset_state

  xmj_render_reinstall_progress \
    'prepare' \
    'running' \
    '准备中' \
    '猫猫正在整理卸载重装的步骤与备份口袋。'

  if ! xmj_reinstall_prepare_log_file; then
    xmj_render_reinstall_result \
      'failure' \
      'prepare' \
      '无法创建卸载重装日志' \
      '请检查脚本目录的写入权限后再试。'
    return 0
  fi

  if ! xmj_reinstall_check_environment; then
    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  xmj_render_reinstall_confirm_page
  xmj_reinstall_prompt_confirm_input
  input="${XMJ_LAST_INPUT:-}"
  case "$input" in
    y|Y|yes|YES|Yes)
      ;;
    *)
      return 0
      ;;
  esac

  xmj_render_reinstall_progress \
    'backup' \
    'running' \
    '自动备份' \
    '正在把 data、third-party 和 config.yaml 打包成 zip 备份。'

  if ! xmj_maintenance_create_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE" '卸载重装'; then
    xmj_reinstall_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成备份压缩包。}"
    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  XMJ_REINSTALL_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
  XMJ_REINSTALL_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"

  xmj_render_reinstall_progress \
    'remove' \
    'running' \
    '卸载旧目录' \
    '自动备份已经完成，正在移除当前酒馆目录。'

  if ! xmj_reinstall_remove_old_dir; then
    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  xmj_render_reinstall_progress \
    'install' \
    'running' \
    '重新安装' \
    '正在重新拉取酒馆代码。'

  if ! xmj_reinstall_clone_repo; then
    XMJ_REINSTALL_DETAIL="${XMJ_REINSTALL_DETAIL} 自动备份已保留，可稍后继续处理。"
    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  xmj_render_reinstall_progress \
    'deps' \
    'running' \
    '同步依赖' \
    '代码已经重新装好，正在确认依赖是否需要补齐。'

  if ! xmj_reinstall_sync_dependencies; then
    xmj_render_reinstall_progress \
      'recover' \
      'running' \
      '恢复备份' \
      '依赖整理没有完成，先把自动备份的内容覆盖恢复回来。'

    if xmj_maintenance_restore_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE"; then
      XMJ_REINSTALL_RESTORE_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
      XMJ_REINSTALL_DETAIL="${XMJ_REINSTALL_DETAIL} ${XMJ_REINSTALL_RESTORE_NOTE}"
    fi

    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  xmj_render_reinstall_progress \
    'recover' \
    'running' \
    '恢复备份' \
    '正在把备份压缩包里的数据与配置覆盖恢复回来。'

  if ! xmj_maintenance_restore_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE"; then
    xmj_reinstall_fail 'recover' '恢复备份失败' "${XMJ_MAINT_LAST_ERROR:-备份压缩包没有顺利恢复。}"
    xmj_render_reinstall_result \
      'failure' \
      "$XMJ_REINSTALL_STAGE" \
      "$XMJ_REINSTALL_SUMMARY" \
      "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  XMJ_REINSTALL_RESTORE_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  XMJ_REINSTALL_AFTER_VERSION="$(xmj_maintenance_repo_version "$XMJ_SILLYTAVERN_PATH" "$XMJ_REINSTALL_LOG_FILE")"
  XMJ_REINSTALL_AFTER_COMMIT="$(git -C "$XMJ_SILLYTAVERN_PATH" rev-parse --short HEAD 2>>"$XMJ_REINSTALL_LOG_FILE" || true)"

  history_note="卸载重装前版本：${XMJ_REINSTALL_BEFORE_VERSION}。重装后版本：${XMJ_REINSTALL_AFTER_VERSION}。"
  if ! xmj_maintenance_record_history '卸载' "$XMJ_REINSTALL_BEFORE_VERSION" "$history_note" 'xmj_reinstall_log_line'; then
    xmj_reinstall_log_line "更新记录写入失败：${XMJ_MAINT_LAST_ERROR:-unknown}"
  fi

  XMJ_REINSTALL_STAGE='done'
  XMJ_REINSTALL_SUMMARY='卸载重装已完成。'
  XMJ_REINSTALL_DETAIL="${XMJ_REINSTALL_BACKUP_NOTE} ${XMJ_REINSTALL_RESTORE_NOTE}"
  xmj_reinstall_log_line "结果摘要：$XMJ_REINSTALL_SUMMARY"
  xmj_reinstall_log_line "结果说明：$XMJ_REINSTALL_DETAIL"

  xmj_render_reinstall_result \
    'success' \
    "$XMJ_REINSTALL_STAGE" \
    "$XMJ_REINSTALL_SUMMARY" \
    "$XMJ_REINSTALL_DETAIL"
  return 0
}
xmj_render_reinstall_confirm_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['04']}" 'reinstall tavern' 'update'
  printf '\n'
  xmj_render_setting_card \
    '即将开始卸载重装' \
    "当前版本：${XMJ_REINSTALL_BEFORE_VERSION}" \
    "目标分支：${XMJ_REINSTALL_BRANCH}"
  printf '\n'
  printf '  %b♡ 执行内容%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '  %b• 会先自动备份，再移除当前酒馆并重新安装。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b• 完成后会把 data、third-party 和 config.yaml 覆盖恢复回来。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '\n'
  printf '  %b输入 y 开始卸载重装；输入其它任意内容取消并返回首页。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_run_update_history_page() {
  local history_file=''
  local total_lines='0'
  local start_line='1'
  local display_lines='18'
  local line=''

  history_file="$(xmj_maintenance_history_file)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['05']}" 'update history' 'update'
  printf '\n'

  if [ ! -f "$history_file" ] || [ ! -s "$history_file" ]; then
    xmj_render_setting_card \
      '还没有历史记录' \
      '当前还没有写入任何更新、回退或卸载条目。' \
      '等你执行真实维护操作后，这里会自动出现记录。'
    xmj_render_page_footer '按回车返回首页'
    return 0
  fi

  total_lines="$(wc -l <"$history_file" 2>/dev/null || true)"
  total_lines="${total_lines//[[:space:]]/}"
  case "$total_lines" in
    ''|*[!0-9]*)
      total_lines='0'
      ;;
  esac

  if [ "$total_lines" -gt "$display_lines" ]; then
    start_line=$((total_lines - display_lines + 1))
  fi

  printf '  %b♡ 最近记录%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  while IFS= read -r line || [ -n "$line" ]; do
    printf '  %b%s%b\n' "$XMJ_WHITE" "$line" "$XMJ_RESET"
  done < <(sed -n "${start_line},${total_lines}p" "$history_file" 2>/dev/null)

  xmj_render_page_footer '按回车返回首页'
}
