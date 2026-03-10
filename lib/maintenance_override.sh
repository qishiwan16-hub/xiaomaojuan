xmj_maintenance_python_cmd() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' 'python3'
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    printf '%s' 'python'
    return 0
  fi

  printf '%s' ''
}

xmj_maintenance_require_archive_tools() {
  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    return 0
  fi

  if [ -n "$(xmj_maintenance_python_cmd)" ]; then
    return 0
  fi

  XMJ_MAINT_LAST_ERROR='未检测到 zip / unzip，也没有可用的 Python，无法自动打包备份。'
  return 1
}

xmj_maintenance_create_archive() {
  local source_dir="${1:-}"
  local bundle_name="${2:-}"
  local archive_file="${3:-}"
  local shell_log="${4:-/dev/null}"
  local python_cmd=''

  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    (
      cd "$source_dir" || exit 1
      zip -rq "$archive_file" "$bundle_name"
    ) >>"$shell_log" 2>&1
    return $?
  fi

  python_cmd="$(xmj_maintenance_python_cmd)"
  if [ -z "$python_cmd" ]; then
    return 1
  fi

  "$python_cmd" - "$source_dir" "$bundle_name" "$archive_file" >>"$shell_log" 2>&1 <<'PY'
import os
import sys
import zipfile

source_dir, bundle_name, archive_file = sys.argv[1:4]
root = os.path.join(source_dir, bundle_name)
if not os.path.isdir(root):
    raise SystemExit(1)

with zipfile.ZipFile(archive_file, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for current_root, dirnames, filenames in os.walk(root):
        rel_root = os.path.relpath(current_root, source_dir)
        if rel_root != ".":
            zf.write(current_root, rel_root)
        for filename in filenames:
            file_path = os.path.join(current_root, filename)
            arcname = os.path.relpath(file_path, source_dir)
            zf.write(file_path, arcname)
PY
}

xmj_maintenance_extract_archive() {
  local archive_file="${1:-}"
  local dest_dir="${2:-}"
  local shell_log="${3:-/dev/null}"
  local python_cmd=''

  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    unzip -oq "$archive_file" -d "$dest_dir" >>"$shell_log" 2>&1
    return $?
  fi

  python_cmd="$(xmj_maintenance_python_cmd)"
  if [ -z "$python_cmd" ]; then
    return 1
  fi

  "$python_cmd" - "$archive_file" "$dest_dir" >>"$shell_log" 2>&1 <<'PY'
import sys
import zipfile

archive_file, dest_dir = sys.argv[1:3]
with zipfile.ZipFile(archive_file, "r") as zf:
    zf.extractall(dest_dir)
PY
}

xmj_maintenance_create_backup() {
  local repo_path="${1:-}"
  local logger_name="${2:-}"
  local log_file="${3:-}"
  local op_name="${4:-维护}"
  local current_version_hint="${5:-}"
  local target_version_hint="${6:-}"
  local shell_log='/dev/null'
  local backup_dir=''
  local archive_name=''
  local archive_file=''
  local bundle_name=''
  local temp_root=''
  local bundle_root=''
  local item=''
  local target_path=''
  local joined_items=''
  local joined_missing=''
  local current_version=''
  local compat_reason=''
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

  current_version="$current_version_hint"
  if [ -z "$current_version" ]; then
    current_version="$(xmj_maintenance_repo_version "$repo_path" "$shell_log")"
  fi

  compat_reason="$(xmj_maintenance_data_only_backup_reason "$current_version" "$target_version_hint")"
  if [ -n "$compat_reason" ]; then
    XMJ_MAINT_BACKUP_SCOPE='data-only'
    XMJ_MAINT_BACKUP_COMPAT_MODE='1'
    XMJ_MAINT_BACKUP_COMPAT_NOTE="$(xmj_maintenance_cross_version_notice)"
  else
    XMJ_MAINT_BACKUP_SCOPE='full'
    XMJ_MAINT_BACKUP_COMPAT_MODE='0'
    XMJ_MAINT_BACKUP_COMPAT_NOTE=''
  fi

  backup_dir="$(xmj_maintenance_backup_dir)"
  if ! mkdir -p "$backup_dir" 2>/dev/null; then
    XMJ_MAINT_LAST_ERROR="无法创建备份目录：$backup_dir"
    return 1
  fi

  archive_name="$(xmj_maintenance_timestamp).zip"
  archive_file="$backup_dir/$archive_name"
  bundle_name="${archive_name%.zip}"

  if [ "${XMJ_MAINT_BACKUP_SCOPE:-full}" = 'data-only' ]; then
    set -- 'data'
  else
    set -- 'data' 'public/scripts/extensions/third-party' 'config.yaml'
  fi

  for item in "$@"; do
    if [ -d "$repo_path/$item" ] || [ -f "$repo_path/$item" ]; then
      items+=("$item")
      item_labels+=("$(xmj_maintenance_backup_label "$item")")
    else
      missing_labels+=("$(xmj_maintenance_backup_label "$item")")
    fi
  done

  joined_items="$(xmj_maintenance_join_labels "${item_labels[@]}")"
  joined_missing="$(xmj_maintenance_join_labels "${missing_labels[@]}")"

  XMJ_MAINT_BACKUP_DIR="$backup_dir"
  XMJ_MAINT_BACKUP_NAME="$archive_name"
  XMJ_MAINT_BACKUP_ITEMS="$joined_items"
  XMJ_MAINT_BACKUP_MISSING_ITEMS="$joined_missing"

  if [ "${#items[@]}" -eq 0 ]; then
    XMJ_MAINT_BACKUP_FILE=''
    if [ "${XMJ_MAINT_BACKUP_SCOPE:-full}" = 'data-only' ]; then
      XMJ_MAINT_BACKUP_NOTE='这次只准备收 data，但当前没有发现 data 文件夹。'
    else
      XMJ_MAINT_BACKUP_NOTE='没有发现 data、third-party 或 config.yaml，已跳过自动备份。'
    fi
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
    if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
      xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_COMPAT_NOTE"
    fi
    return 0
  fi

  if ! xmj_maintenance_require_archive_tools; then
    return 1
  fi

  rm -f "$archive_file" 2>/dev/null || true
  temp_root="$(mktemp -d "$backup_dir/.xmj-backup-XXXXXX" 2>/dev/null || true)"
  if [ -z "$temp_root" ]; then
    temp_root="$backup_dir/.xmj-backup-${bundle_name}-$$"
    if ! mkdir -p "$temp_root" 2>/dev/null; then
      XMJ_MAINT_LAST_ERROR='无法准备自动备份临时目录。'
      return 1
    fi
  fi

  bundle_root="$temp_root/$bundle_name"
  if ! mkdir -p "$bundle_root" 2>/dev/null; then
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='无法准备自动备份临时目录。'
    return 1
  fi

  if ! xmj_maintenance_write_backup_meta "$bundle_root"; then
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='无法写入备份元信息。'
    return 1
  fi

  xmj_maintenance_log "$logger_name" "开始为${op_name}自动打包备份。"
  xmj_backup_start_busy '生成备份中'

  for item in "${items[@]}"; do
    target_path="$bundle_root/$item"
    if ! mkdir -p "$(dirname "$target_path")" 2>/dev/null; then
      xmj_backup_stop_busy
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='整理自动备份内容时失败。'
      return 1
    fi

    if ! cp -a "$repo_path/$item" "$target_path" 2>>"$shell_log"; then
      xmj_backup_stop_busy
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='整理自动备份内容时失败。'
      return 1
    fi
  done

  if ! xmj_maintenance_create_archive "$temp_root" "$bundle_name" "$archive_file" "$shell_log"; then
    xmj_backup_stop_busy
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='生成备份压缩包失败，可温和查看日志。'
    return 1
  fi

  rm -rf "$temp_root" 2>/dev/null || true
  xmj_backup_stop_busy

  XMJ_MAINT_BACKUP_FILE="$archive_file"
  if [ "${XMJ_MAINT_BACKUP_SCOPE:-full}" = 'data-only' ]; then
    XMJ_MAINT_BACKUP_NOTE="${compat_reason}，这次只把 ${joined_items} 打成了 1 个备份压缩包。"
  else
    XMJ_MAINT_BACKUP_NOTE="已把 ${joined_items} 打成 1 个备份压缩包。"
  fi
  if [ -n "$joined_missing" ]; then
    XMJ_MAINT_BACKUP_NOTE="${XMJ_MAINT_BACKUP_NOTE} 本次未发现 ${joined_missing}。"
  fi

  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_COMPAT_NOTE"
  fi
  return 0
}

xmj_maintenance_restore_backup() {
  local repo_path="${1:-}"
  local logger_name="${2:-}"
  local log_file="${3:-}"
  local shell_log='/dev/null'
  local temp_root=''
  local bundle_root=''
  local archive_root=''
  local item=''
  local source_path=''
  local target_path=''
  local restored_count='0'
  local restored_items=''

  if [ -n "$log_file" ]; then
    shell_log="$log_file"
  fi

  if [ -z "${XMJ_MAINT_BACKUP_FILE:-}" ] || [ ! -f "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
    XMJ_MAINT_BACKUP_RESTORE_NOTE='这次没有可恢复的备份内容。'
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_RESTORE_NOTE"
    return 0
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

  temp_root="$(mktemp -d "$repo_path/.xmj-restore-XXXXXX" 2>/dev/null || true)"
  if [ -z "$temp_root" ]; then
    temp_root="$repo_path/.xmj-restore-$$"
    if ! mkdir -p "$temp_root" 2>/dev/null; then
      XMJ_MAINT_LAST_ERROR='无法准备恢复临时目录。'
      return 1
    fi
  fi

  xmj_maintenance_log "$logger_name" '开始从自动备份压缩包恢复内容。'
  xmj_backup_start_busy '恢复备份中'

  if ! xmj_maintenance_extract_archive "$XMJ_MAINT_BACKUP_FILE" "$temp_root" "$shell_log"; then
    xmj_backup_stop_busy
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='解压备份压缩包失败，可温和查看日志。'
    return 1
  fi

  archive_root="$temp_root/${XMJ_MAINT_BACKUP_NAME%.zip}"
  if [ -d "$archive_root" ]; then
    bundle_root="$archive_root"
  else
    bundle_root="$temp_root"
  fi

  XMJ_MAINT_BACKUP_SCOPE='full'
  XMJ_MAINT_BACKUP_COMPAT_MODE='0'
  XMJ_MAINT_BACKUP_COMPAT_NOTE=''
  xmj_maintenance_load_backup_meta "$bundle_root" || true

  for item in 'data' 'public/scripts/extensions/third-party' 'config.yaml'; do
    source_path="$bundle_root/$item"
    if [ ! -d "$source_path" ] && [ ! -f "$source_path" ]; then
      continue
    fi

    target_path="$repo_path/$item"
    rm -rf "$target_path" 2>/dev/null || true
    if ! mkdir -p "$(dirname "$target_path")" 2>/dev/null; then
      xmj_backup_stop_busy
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='恢复备份内容时失败。'
      return 1
    fi

    if ! cp -a "$source_path" "$target_path" 2>>"$shell_log"; then
      xmj_backup_stop_busy
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='恢复备份内容时失败。'
      return 1
    fi

    restored_items="$(xmj_maintenance_join_labels "$restored_items" "$(xmj_maintenance_backup_label "$item")")"
    restored_count=$((restored_count + 1))
  done

  rm -rf "$temp_root" 2>/dev/null || true
  xmj_backup_stop_busy

  if [ "$restored_count" -eq 0 ]; then
    XMJ_MAINT_LAST_ERROR='备份压缩包里没有可恢复的目标内容。'
    return 1
  fi

  if [ "${XMJ_MAINT_BACKUP_SCOPE:-full}" = 'data-only' ]; then
    XMJ_MAINT_BACKUP_RESTORE_NOTE='已把备份里的 data 文件夹覆盖恢复回原位置。'
  else
    XMJ_MAINT_BACKUP_RESTORE_NOTE='已把备份压缩包中的内容覆盖恢复到原位置。'
  fi
  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_COMPAT_NOTE"
  fi
  return 0
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
  XMJ_REINSTALL_OPERATION=''
  XMJ_REINSTALL_TARGET_EXISTS='0'
  XMJ_REINSTALL_CAN_BACKUP='0'
  XMJ_REINSTALL_BACKUP_ENABLED=''
  XMJ_REINSTALL_MENU_NOTICE=''
  XMJ_REINSTALL_MENU_NOTICE_KIND='info'
  XMJ_REINSTALL_CONFIRM_NOTICE=''
  XMJ_REINSTALL_CONFIRM_NOTICE_KIND='info'
}

xmj_reinstall_default_repo_url() {
  printf '%s' 'https://github.com/SillyTavern/SillyTavern.git'
}

xmj_reinstall_action_label() {
  case "${XMJ_REINSTALL_OPERATION:-}" in
    uninstall)
      printf '%s' '卸载酒馆'
      ;;
    reinstall)
      printf '%s' '重装酒馆'
      ;;
    *)
      printf '%s' "${XMJ_MENU_LABEL['04']}"
      ;;
  esac
}

xmj_reinstall_action_phrase() {
  case "${XMJ_REINSTALL_OPERATION:-}" in
    uninstall)
      printf '%s' 'uninstall tavern'
      ;;
    reinstall)
      printf '%s' 'reinstall tavern'
      ;;
    *)
      printf '%s' 'maintenance room'
      ;;
  esac
}

xmj_reinstall_notice_color() {
  case "${1:-info}" in
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_reinstall_append_detail() {
  local base_text="${1:-}"
  local extra_text="${2:-}"

  if [ -z "$extra_text" ]; then
    printf '%s' "$base_text"
    return 0
  fi

  if [ -z "$base_text" ]; then
    printf '%s' "$extra_text"
    return 0
  fi

  printf '%s %s' "$base_text" "$extra_text"
}

xmj_reinstall_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local shell_log='/dev/null'
  local repo_flag=''

  if ! xmj_reinstall_assert_safe_target; then
    return 1
  fi

  if [ -n "${XMJ_REINSTALL_LOG_FILE:-}" ]; then
    shell_log="$XMJ_REINSTALL_LOG_FILE"
  fi

  XMJ_REINSTALL_TARGET_EXISTS='0'
  XMJ_REINSTALL_CAN_BACKUP='0'
  XMJ_REINSTALL_REPO_URL="$(xmj_reinstall_default_repo_url)"
  XMJ_REINSTALL_BRANCH='release'
  XMJ_REINSTALL_BEFORE_VERSION='未知'

  case "${XMJ_REINSTALL_OPERATION:-}" in
    uninstall)
      if [ ! -d "$repo_path" ]; then
        xmj_reinstall_fail 'env' '未找到现有酒馆目录' '当前没有可卸载的酒馆目录。'
        return 1
      fi

      XMJ_REINSTALL_TARGET_EXISTS='1'
      XMJ_REINSTALL_CAN_BACKUP='1'
      XMJ_REINSTALL_BEFORE_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$shell_log")"
      xmj_reinstall_log_line "卸载前版本：${XMJ_REINSTALL_BEFORE_VERSION}"
      return 0
      ;;
    reinstall)
      if ! command -v git >/dev/null 2>&1; then
        xmj_reinstall_fail 'env' '未检测到 Git' '请先在 Termux 中安装 git 后再试。'
        return 1
      fi

      if [ -d "$repo_path" ]; then
        XMJ_REINSTALL_TARGET_EXISTS='1'
        XMJ_REINSTALL_CAN_BACKUP='1'
        XMJ_REINSTALL_BEFORE_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$shell_log")"
        repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$shell_log" || true)"

        if [ "$repo_flag" = 'true' ]; then
          XMJ_REINSTALL_REPO_URL="$(git -C "$repo_path" remote get-url origin 2>>"$shell_log" || true)"
          if [ -z "$XMJ_REINSTALL_REPO_URL" ]; then
            XMJ_REINSTALL_REPO_URL="$(xmj_reinstall_default_repo_url)"
          fi

          XMJ_REINSTALL_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$shell_log" || true)"
          if [ -z "$XMJ_REINSTALL_BRANCH" ]; then
            XMJ_REINSTALL_BRANCH='release'
          fi
        else
          XMJ_REINSTALL_REPO_URL="$(xmj_reinstall_default_repo_url)"
          XMJ_REINSTALL_BRANCH='release'
          xmj_reinstall_log_line '当前目录不是 Git 仓库，重装时会使用默认仓库与 release 分支。'
        fi
      else
        XMJ_REINSTALL_TARGET_EXISTS='0'
        XMJ_REINSTALL_CAN_BACKUP='0'
        XMJ_REINSTALL_BEFORE_VERSION='未安装'
        XMJ_REINSTALL_REPO_URL="$(xmj_reinstall_default_repo_url)"
        XMJ_REINSTALL_BRANCH='release'
        xmj_reinstall_log_line '当前没有旧酒馆目录，这次会直接重新安装。'
      fi

      xmj_reinstall_log_line "重装来源：${XMJ_REINSTALL_REPO_URL}"
      xmj_reinstall_log_line "目标分支：${XMJ_REINSTALL_BRANCH}"
      return 0
      ;;
    *)
      xmj_reinstall_fail 'env' '未选择维护操作' '请先选择要执行卸载还是重装。'
      return 1
      ;;
  esac
}

xmj_render_reinstall_stage_group() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"

  xmj_render_reinstall_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_reinstall_stage_line 'env' "$current_stage" "$stage_mode"

  if [ "${XMJ_REINSTALL_BACKUP_ENABLED:-0}" = '1' ]; then
    xmj_render_reinstall_stage_line 'backup' "$current_stage" "$stage_mode"
  fi

  xmj_render_reinstall_stage_line 'remove' "$current_stage" "$stage_mode"

  if [ "${XMJ_REINSTALL_OPERATION:-}" = 'reinstall' ]; then
    xmj_render_reinstall_stage_line 'install' "$current_stage" "$stage_mode"
    xmj_render_reinstall_stage_line 'deps' "$current_stage" "$stage_mode"

    if [ "${XMJ_REINSTALL_BACKUP_ENABLED:-0}" = '1' ]; then
      xmj_render_reinstall_stage_line 'recover' "$current_stage" "$stage_mode"
    fi
  fi

  xmj_render_reinstall_stage_line 'done' "$current_stage" "$stage_mode"
}

xmj_render_reinstall_action_page() {
  local notice_color=''

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['04']}" 'maintenance mode' 'update'
  printf '\n'
  xmj_render_setting_card '1 · 卸载酒馆' '只移除当前酒馆目录。' '开始前会询问是否先备份。'
  printf '\n'
  xmj_render_setting_card '2 · 重装酒馆' '删除后重新安装酒馆。' '开始前会询问是否先备份。'

  if [ -n "${XMJ_REINSTALL_MENU_NOTICE:-}" ]; then
    notice_color="$(xmj_reinstall_notice_color "${XMJ_REINSTALL_MENU_NOTICE_KIND:-info}")"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_REINSTALL_MENU_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_render_action_item '1' '进入卸载酒馆'
  xmj_render_action_item '2' '进入重装酒馆'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 0'
}

xmj_reinstall_prompt_action_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  操作序号 / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_reinstall_confirm_page() {
  local notice_color=''
  local summary_text=''
  local detail_text=''

  case "${XMJ_REINSTALL_OPERATION:-}" in
    uninstall)
      summary_text="当前版本：${XMJ_REINSTALL_BEFORE_VERSION:-未知}"
      detail_text='这次只会卸载酒馆，不会重新安装。'
      ;;
    reinstall)
      if [ "${XMJ_REINSTALL_TARGET_EXISTS:-0}" = '1' ]; then
        summary_text="当前版本：${XMJ_REINSTALL_BEFORE_VERSION:-未知}"
        detail_text="目标分支：${XMJ_REINSTALL_BRANCH:-release}"
      else
        summary_text='当前没有旧酒馆目录'
        detail_text="会直接安装到：${XMJ_REINSTALL_BRANCH:-release}"
      fi
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_reinstall_action_label)" "$(xmj_reinstall_action_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card '执行前确认' "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 备份说明%b\n' "$XMJ_PINK" "$XMJ_RESET"

  if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
    printf '  %b• 自动备份会把 data、third-party 和 config.yaml 打成 1 个备份压缩包。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '  %b• 备份压缩包会统一放进脚本固定创建的备份文件夹。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
    printf '  %b输入 y：先备份再继续；输入 n：直接继续不备份；输入 0：取消。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  else
    printf '  %b• 当前没有旧酒馆目录，这次没有可备份内容。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
    printf '  %b输入 y：直接继续；输入 0：取消。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  fi

  if [ -n "${XMJ_REINSTALL_CONFIRM_NOTICE:-}" ]; then
    notice_color="$(xmj_reinstall_notice_color "${XMJ_REINSTALL_CONFIRM_NOTICE_KIND:-info}")"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_REINSTALL_CONFIRM_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_reinstall_prompt_backup_input() {
  if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
    printf '%b%s%b' "$XMJ_PINK_SOFT" '  y 备份继续 / n 不备份继续 / 0 取消 > ' "$XMJ_RESET"
  else
    printf '%b%s%b' "$XMJ_PINK_SOFT" '  y 继续 / 0 取消 > ' "$XMJ_RESET"
  fi
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_reinstall_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理维护步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_reinstall_action_label)" "$(xmj_reinstall_action_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ %s进度%b\n' "$XMJ_PINK" "$(xmj_reinstall_action_label)" "$XMJ_RESET"
  xmj_render_reinstall_stage_group "$current_stage" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_reinstall_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-维护已完成。}"
  local detail_text="${4:-}"
  local result_title='已完成'
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='执行失败'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_reinstall_action_label)" "$(xmj_reinstall_action_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ %s进度%b\n' "$XMJ_PINK" "$(xmj_reinstall_action_label)" "$XMJ_RESET"
  xmj_render_reinstall_stage_group "$current_stage" "$stage_mode"

  if [ "${XMJ_REINSTALL_OPERATION:-}" = 'reinstall' ] \
    && [ "$result_mode" = 'success' ] \
    && [ -n "${XMJ_REINSTALL_AFTER_VERSION:-}" ] \
    && [ "${XMJ_REINSTALL_AFTER_VERSION:-}" != '未知' ]; then
    printf '\n'
    xmj_render_fact_line '当前版本' "${XMJ_REINSTALL_AFTER_VERSION}"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_run_tavern_uninstall_flow() {
  local history_note=''

  if [ "${XMJ_REINSTALL_BACKUP_ENABLED:-0}" = '1' ]; then
    xmj_render_reinstall_progress \
      'backup' \
      'running' \
      '自动备份' \
      "$(xmj_maintenance_backup_stage_text "${XMJ_REINSTALL_BEFORE_VERSION:-}" '')"

    if ! xmj_maintenance_create_backup \
      "$XMJ_SILLYTAVERN_PATH" \
      'xmj_reinstall_log_line' \
      "$XMJ_REINSTALL_LOG_FILE" \
      '卸载酒馆' \
      "${XMJ_REINSTALL_BEFORE_VERSION:-}" \
      ''; then
      xmj_reinstall_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成备份压缩包。}"
      xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
      return 0
    fi

    XMJ_REINSTALL_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
    XMJ_REINSTALL_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
  else
    XMJ_REINSTALL_BACKUP_NOTE='这次按你的选择跳过了备份。'
  fi

  xmj_render_reinstall_progress \
    'remove' \
    'running' \
    '卸载酒馆' \
    '正在移除当前酒馆目录。'

  if ! xmj_reinstall_remove_old_dir; then
    xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  history_note="卸载前版本：${XMJ_REINSTALL_BEFORE_VERSION:-未知}。"
  if ! xmj_maintenance_record_history '卸载' "${XMJ_REINSTALL_BEFORE_VERSION:-未知}" "$history_note" 'xmj_reinstall_log_line'; then
    xmj_reinstall_log_line "更新记录写入失败：${XMJ_MAINT_LAST_ERROR:-unknown}"
  fi

  XMJ_REINSTALL_STAGE='done'
  XMJ_REINSTALL_SUMMARY='卸载酒馆已完成。'
  XMJ_REINSTALL_DETAIL="$XMJ_REINSTALL_BACKUP_NOTE"
  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    XMJ_REINSTALL_DETAIL="$(xmj_reinstall_append_detail "$XMJ_REINSTALL_DETAIL" "$XMJ_MAINT_BACKUP_COMPAT_NOTE")"
  fi
  xmj_render_reinstall_result 'success' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
  return 0
}

xmj_run_tavern_reinstall_flow() {
  local detail_text=''

  if [ "${XMJ_REINSTALL_BACKUP_ENABLED:-0}" = '1' ]; then
    xmj_render_reinstall_progress \
      'backup' \
      'running' \
      '自动备份' \
      "$(xmj_maintenance_backup_stage_text "${XMJ_REINSTALL_BEFORE_VERSION:-}" '')"

    if ! xmj_maintenance_create_backup \
      "$XMJ_SILLYTAVERN_PATH" \
      'xmj_reinstall_log_line' \
      "$XMJ_REINSTALL_LOG_FILE" \
      '重装酒馆' \
      "${XMJ_REINSTALL_BEFORE_VERSION:-}" \
      ''; then
      xmj_reinstall_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成备份压缩包。}"
      xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
      return 0
    fi

    XMJ_REINSTALL_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
    XMJ_REINSTALL_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
  else
    XMJ_REINSTALL_BACKUP_NOTE='这次按你的选择跳过了备份。'
  fi

  if [ "${XMJ_REINSTALL_TARGET_EXISTS:-0}" = '1' ]; then
    xmj_render_reinstall_progress \
      'remove' \
      'running' \
      '卸载旧酒馆' \
      '正在移除当前酒馆目录。'

    if ! xmj_reinstall_remove_old_dir; then
      xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
      return 0
    fi
  else
    xmj_reinstall_log_line '当前没有旧酒馆目录，已跳过卸载阶段。'
  fi

  xmj_render_reinstall_progress \
    'install' \
    'running' \
    '重新安装' \
    '正在重新拉取酒馆代码。'

  if ! xmj_reinstall_clone_repo; then
    XMJ_REINSTALL_DETAIL="$(xmj_reinstall_append_detail "$XMJ_REINSTALL_DETAIL" '备份压缩包已保留，可稍后继续处理。')"
    xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  xmj_render_reinstall_progress \
    'deps' \
    'running' \
    '同步依赖' \
    '代码已经重新装好，正在整理依赖。'

  if ! xmj_reinstall_sync_dependencies; then
    if [ -n "${XMJ_REINSTALL_BACKUP_FILE:-}" ]; then
      xmj_render_reinstall_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '依赖整理没有完成，先把备份内容覆盖恢复回来。'

      if xmj_maintenance_restore_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE"; then
        XMJ_REINSTALL_RESTORE_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
        XMJ_REINSTALL_DETAIL="$(xmj_reinstall_append_detail "$XMJ_REINSTALL_DETAIL" "$XMJ_REINSTALL_RESTORE_NOTE")"
      fi
    fi

    xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  if [ -n "${XMJ_REINSTALL_BACKUP_FILE:-}" ]; then
    xmj_render_reinstall_progress \
      'recover' \
      'running' \
      '恢复备份' \
      '正在把备份压缩包中的数据与配置覆盖恢复回来。'

    if ! xmj_maintenance_restore_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE"; then
      xmj_reinstall_fail 'recover' '恢复备份失败' "${XMJ_MAINT_LAST_ERROR:-备份压缩包没有顺利恢复。}"
      xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
      return 0
    fi

    XMJ_REINSTALL_RESTORE_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  else
    XMJ_REINSTALL_RESTORE_NOTE=''
  fi

  XMJ_REINSTALL_AFTER_VERSION="$(xmj_maintenance_repo_version "$XMJ_SILLYTAVERN_PATH" "$XMJ_REINSTALL_LOG_FILE")"
  XMJ_REINSTALL_AFTER_COMMIT="$(git -C "$XMJ_SILLYTAVERN_PATH" rev-parse --short HEAD 2>>"$XMJ_REINSTALL_LOG_FILE" || true)"

  detail_text="$(xmj_reinstall_append_detail "$detail_text" "$XMJ_REINSTALL_BACKUP_NOTE")"
  detail_text="$(xmj_reinstall_append_detail "$detail_text" "$XMJ_REINSTALL_RESTORE_NOTE")"
  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    detail_text="$(xmj_reinstall_append_detail "$detail_text" "$XMJ_MAINT_BACKUP_COMPAT_NOTE")"
  fi

  XMJ_REINSTALL_STAGE='done'
  if [ "${XMJ_REINSTALL_TARGET_EXISTS:-0}" = '1' ]; then
    XMJ_REINSTALL_SUMMARY='重装酒馆已完成。'
  else
    XMJ_REINSTALL_SUMMARY='酒馆已安装完成。'
  fi
  XMJ_REINSTALL_DETAIL="$detail_text"
  xmj_render_reinstall_result 'success' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
  return 0
}

xmj_run_tavern_reinstall() {
  local input=''
  local selected_operation=''

  xmj_reinstall_reset_state

  while true; do
    xmj_render_reinstall_action_page
    xmj_reinstall_prompt_action_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      1)
        selected_operation='uninstall'
        break
        ;;
      2)
        selected_operation='reinstall'
        break
        ;;
      0)
        return 0
        ;;
      *)
        XMJ_REINSTALL_MENU_NOTICE='这里只支持输入 1 / 2 / 0。'
        XMJ_REINSTALL_MENU_NOTICE_KIND='warn'
        ;;
    esac
  done

  xmj_reinstall_reset_state
  XMJ_REINSTALL_OPERATION="$selected_operation"

  xmj_render_reinstall_progress \
    'prepare' \
    'running' \
    '准备中' \
    '猫猫正在整理这次维护的步骤。'

  if ! xmj_reinstall_prepare_log_file; then
    xmj_render_reinstall_result 'failure' 'prepare' '无法创建维护日志' '请检查脚本目录的写入权限后再试。'
    return 0
  fi

  if ! xmj_reinstall_check_environment; then
    xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
    return 0
  fi

  while true; do
    xmj_render_reinstall_confirm_page
    xmj_reinstall_prompt_backup_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
          XMJ_REINSTALL_BACKUP_ENABLED='1'
        else
          XMJ_REINSTALL_BACKUP_ENABLED='0'
          XMJ_REINSTALL_BACKUP_NOTE='当前没有旧酒馆目录，这次没有备份内容。'
        fi
        break
        ;;
      n|N|no|NO|No)
        if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
          XMJ_REINSTALL_BACKUP_ENABLED='0'
          XMJ_REINSTALL_BACKUP_NOTE='这次按你的选择跳过了备份。'
          break
        fi

        XMJ_REINSTALL_CONFIRM_NOTICE='当前没有旧酒馆目录，这里只能继续或取消。'
        XMJ_REINSTALL_CONFIRM_NOTICE_KIND='warn'
        ;;
      0)
        return 0
        ;;
      *)
        if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
          XMJ_REINSTALL_CONFIRM_NOTICE='请输入 y / n / 0。'
        else
          XMJ_REINSTALL_CONFIRM_NOTICE='请输入 y / 0。'
        fi
        XMJ_REINSTALL_CONFIRM_NOTICE_KIND='warn'
        ;;
    esac
  done

  case "${XMJ_REINSTALL_OPERATION:-}" in
    uninstall)
      xmj_run_tavern_uninstall_flow
      ;;
    reinstall)
      xmj_run_tavern_reinstall_flow
      ;;
  esac
}

xmj_maintenance_backup_dir() {
  if [ -n "${XMJ_BACKUP_DIR:-}" ]; then
    printf '%s' "$XMJ_BACKUP_DIR"
    return 0
  fi

  printf '%s/备份' "${XMJ_ROOT_DIR:-.}"
}

declare -ga XMJ_BACKUP_ARCHIVE_FILES=()
declare -ga XMJ_BACKUP_ARCHIVE_SCOPES=()

xmj_backup_busy_tip() {
  case "${1:-备份处理中}" in
    '生成备份中')
      printf '%s' '₍˄·͈༝·͈˄₎♡ 正在把数据、配置和扩展轻轻收进小口袋。'
      ;;
    '恢复备份中')
      printf '%s' '₍ᐢ..ᐢ₎♡ 正在把记忆温柔放回原来的位置。'
      ;;
    '删除备份中')
      printf '%s' '₍˃ ⤙ ˂₎੭ु⁾⁾ 正在悄悄移走这份旧备份。'
      ;;
    '清理旧档中')
      printf '%s' 'ฅ^•ﻌ•^ฅ 正在整理旧档，只留下较新的几份。'
      ;;
    *)
      printf '%s' '猫猫正在安静处理这份备份相关操作。'
      ;;
  esac
}

xmj_render_backup_busy_frame() {
  local action_text="${1:-备份处理中}"
  local detail_text=''

  detail_text="$(xmj_backup_busy_tip "$action_text")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '备份处理中' 'memory archive' 'backup'
  printf '\n'
  xmj_render_setting_card "$action_text" '命令细节已隐藏，猫猫正在安静处理。' "$detail_text"
  printf '\n'
  printf '  %b(ฅ́˘ฅ̀)♡ %s%b\n' "$XMJ_PINK" "$action_text" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_backup_start_busy() {
  local action_text="${1:-备份处理中}"

  xmj_render_backup_busy_frame "$action_text"
}

xmj_backup_stop_busy() {
  return 0
}

xmj_backup_notice_color() {
  case "${1:-info}" in
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    success)
      printf '%s' "$XMJ_CREAM"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_backup_clear_notice() {
  XMJ_BACKUP_NOTICE=''
  XMJ_BACKUP_NOTICE_KIND='info'
}

xmj_backup_set_notice() {
  XMJ_BACKUP_NOTICE_KIND="${1:-info}"
  XMJ_BACKUP_NOTICE="${2:-}"
}

xmj_render_backup_notice() {
  local notice_text="${XMJ_BACKUP_NOTICE:-}"
  local notice_color=''

  if [ -z "$notice_text" ]; then
    return 0
  fi

  notice_color="$(xmj_backup_notice_color "${XMJ_BACKUP_NOTICE_KIND:-info}")"
  printf '\n'
  printf '  %b%s%b\n' "$notice_color" "$notice_text" "$XMJ_RESET"
}

xmj_backup_page_size() {
  printf '%s' '5'
}

xmj_backup_total_pages() {
  local total="${1:-0}"
  local page_size="${2:-5}"

  case "$total" in
    ''|*[!0-9]*)
      total='0'
      ;;
  esac

  case "$page_size" in
    ''|*[!0-9]*)
      page_size='5'
      ;;
  esac

  if [ "$page_size" -le 0 ]; then
    page_size='5'
  fi

  if [ "$total" -le 0 ]; then
    printf '%s' '1'
    return 0
  fi

  printf '%s' "$(((total + page_size - 1) / page_size))"
}

xmj_backup_normalize_page() {
  local page="${1:-1}"
  local total_pages="${2:-1}"

  case "$page" in
    ''|*[!0-9]*)
      page='1'
      ;;
  esac

  case "$total_pages" in
    ''|*[!0-9]*)
      total_pages='1'
      ;;
  esac

  if [ "$page" -lt 1 ]; then
    page='1'
  fi

  if [ "$total_pages" -lt 1 ]; then
    total_pages='1'
  fi

  if [ "$page" -gt "$total_pages" ]; then
    page="$total_pages"
  fi

  printf '%s' "$page"
}

xmj_backup_archive_size_text() {
  local archive_file="${1:-}"
  local bytes='0'

  if [ -z "$archive_file" ] || [ ! -f "$archive_file" ]; then
    printf '%s' '未知'
    return 0
  fi

  bytes="$(wc -c <"$archive_file" 2>/dev/null || true)"
  bytes="${bytes//[[:space:]]/}"
  case "$bytes" in
    ''|*[!0-9]*)
      bytes='0'
      ;;
  esac

  if [ "$bytes" -ge 1048576 ]; then
    printf '%s MB' "$(((bytes + 1048575) / 1048576))"
    return 0
  fi

  if [ "$bytes" -ge 1024 ]; then
    printf '%s KB' "$(((bytes + 1023) / 1024))"
    return 0
  fi

  printf '%s B' "$bytes"
}

xmj_backup_archive_time_text() {
  local archive_file="${1:-}"
  local archive_name=''
  local time_text=''

  if [ -z "$archive_file" ]; then
    printf '%s' '未知时间'
    return 0
  fi

  time_text="$(date -r "$archive_file" '+%Y-%m-%d %H:%M' 2>/dev/null || true)"
  if [ -n "$time_text" ]; then
    printf '%s' "$time_text"
    return 0
  fi

  archive_name="$(basename "$archive_file")"
  printf '%s' "${archive_name%.zip}"
}

xmj_backup_join_scope_labels() {
  local joined=''
  local label=''

  for label in "$@"; do
    if [ -z "$label" ]; then
      continue
    fi

    if [ -n "$joined" ]; then
      joined="${joined} / "
    fi
    joined="${joined}${label}"
  done

  printf '%s' "$joined"
}

xmj_backup_archive_entry_lines() {
  local archive_file="${1:-}"
  local python_cmd=''

  if [ -z "$archive_file" ] || [ ! -f "$archive_file" ]; then
    return 1
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -Z1 "$archive_file" 2>/dev/null
    return $?
  fi

  python_cmd="$(xmj_maintenance_python_cmd)"
  if [ -z "$python_cmd" ]; then
    return 1
  fi

  "$python_cmd" - "$archive_file" 2>/dev/null <<'PY'
import sys
import zipfile

archive_file = sys.argv[1]

with zipfile.ZipFile(archive_file, "r") as zf:
    for name in zf.namelist():
        print(name)
PY
}

xmj_backup_archive_scope_text() {
  local archive_file="${1:-}"
  local entry=''
  local normalized=''
  local has_data='0'
  local has_third_party='0'
  local has_config='0'
  local labels=()
  local joined=''

  if [ -z "$archive_file" ] || [ ! -f "$archive_file" ]; then
    printf '%s' '范围未知'
    return 0
  fi

  while IFS= read -r entry || [ -n "$entry" ]; do
    if [ -z "$entry" ]; then
      continue
    fi

    normalized="${entry%/}"
    case "$normalized" in
      data|data/*|*/data|*/data/*)
        has_data='1'
        ;;
      public/scripts/extensions/third-party|public/scripts/extensions/third-party/*|*/public/scripts/extensions/third-party|*/public/scripts/extensions/third-party/*)
        has_third_party='1'
        ;;
      config.yaml|*/config.yaml)
        has_config='1'
        ;;
    esac
  done < <(xmj_backup_archive_entry_lines "$archive_file")

  if [ "$has_data" = '1' ]; then
    labels+=('data')
  fi
  if [ "$has_third_party" = '1' ]; then
    labels+=('third-party')
  fi
  if [ "$has_config" = '1' ]; then
    labels+=('config.yaml')
  fi

  if [ "${#labels[@]}" -eq 0 ]; then
    printf '%s' '范围未知'
    return 0
  fi

  joined="$(xmj_backup_join_scope_labels "${labels[@]}")"
  if [ "${#labels[@]}" -eq 1 ]; then
    printf '仅 %s' "$joined"
    return 0
  fi

  printf '%s' "$joined"
}

xmj_backup_refresh_archives() {
  local backup_dir=''
  local archive_file=''

  XMJ_BACKUP_ARCHIVE_FILES=()
  XMJ_BACKUP_ARCHIVE_SCOPES=()
  backup_dir="$(xmj_maintenance_backup_dir)"

  if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
    return 0
  fi

  while IFS= read -r archive_file || [ -n "$archive_file" ]; do
    if [ -z "$archive_file" ]; then
      continue
    fi

    XMJ_BACKUP_ARCHIVE_FILES+=("$archive_file")
    XMJ_BACKUP_ARCHIVE_SCOPES+=("$(xmj_backup_archive_scope_text "$archive_file")")
  done < <(find "$backup_dir" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | LC_ALL=C sort -r)

  return 0
}

xmj_render_backup_archive_lines() {
  local page="${1:-1}"
  local page_size="${2:-5}"
  local total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
  local start_index='0'
  local end_index='0'
  local i='0'
  local archive_file=''
  local archive_name=''

  if [ "$total" -eq 0 ]; then
    xmj_render_setting_card \
      '还没有备份档' \
      '当前备份目录里还没有 zip 备份。' \
      '可以先进入 07 创建备份，再回来查看。'
    return 0
  fi

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size))
  if [ "$end_index" -gt "$total" ]; then
    end_index="$total"
  fi

  printf '  %b♡ 备份档案%b\n' "$XMJ_PINK" "$XMJ_RESET"

  for ((i = start_index; i < end_index; i++)); do
    archive_file="${XMJ_BACKUP_ARCHIVE_FILES[$i]}"
    archive_name="$(basename "$archive_file")"

    printf '\n'
    printf '  %b[%02d]%b %b%s%b\n' \
      "$XMJ_PINK" $((i + 1)) "$XMJ_RESET" \
      "$XMJ_WHITE" "$archive_name" "$XMJ_RESET"
    printf '      %b时间%b：%b%s%b   %b大小%b：%b%s%b\n' \
      "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$(xmj_backup_archive_time_text "$archive_file")" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$(xmj_backup_archive_size_text "$archive_file")" "$XMJ_RESET"
  done
}

xmj_backup_prompt_create_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  y 创建备份 / 0 返回 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_backup_create_page() {
  local backup_dir=''
  local current_version=''

  backup_dir="$(xmj_maintenance_backup_dir)"
  current_version="$(xmj_maintenance_repo_version "${XMJ_SILLYTAVERN_PATH:-}" '')"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['07']}" 'create backup' 'backup'
  printf '\n'
  xmj_render_page_intro \
    "$(xmj_maintenance_backup_preview_note "$current_version" '')" \
    '缺少的内容会自动跳过，已有内容会被猫猫收进同一个 zip。'
  printf '\n'
  xmj_render_fact_line '酒馆目录' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_fact_line '备份目录' "$(xmj_display_path "$backup_dir")"
  xmj_render_fact_line '打包范围' "$(xmj_maintenance_backup_scope_text "$current_version" '')"
  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'y' '立即创建手动备份'
  xmj_render_action_item '0' '取消并返回首页'
  xmj_render_action_footer '输入 y / 0。'
}

xmj_render_backup_create_result() {
  local result_mode="${1:-success}"
  local summary_text="${2:-手动备份已完成。}"
  local detail_text="${3:-}"
  local card_title='创建完成'

  if [ "$result_mode" = 'failure' ]; then
    card_title='创建失败'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['07']}" 'create backup' 'backup'
  printf '\n'
  xmj_render_setting_card "$card_title" "$summary_text" "$detail_text"

  if [ -n "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '备份文件' "$(xmj_display_path "$XMJ_MAINT_BACKUP_FILE")"
  fi

  if [ -n "${XMJ_MAINT_BACKUP_ITEMS:-}" ]; then
    xmj_render_fact_line '已收纳内容' "$XMJ_MAINT_BACKUP_ITEMS"
  fi

  if [ -n "${XMJ_MAINT_BACKUP_MISSING_ITEMS:-}" ]; then
    xmj_render_fact_line '本次跳过' "$XMJ_MAINT_BACKUP_MISSING_ITEMS"
  fi

  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    printf '\n'
    printf '  %b%s%b\n' "$XMJ_WARN" "$XMJ_MAINT_BACKUP_COMPAT_NOTE" "$XMJ_RESET"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_run_backup_create_page() {
  local input=''

  xmj_backup_clear_notice
  xmj_maintenance_clear_state

  while true; do
    xmj_render_backup_create_page
    xmj_backup_prompt_create_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        break
        ;;
      0)
        return 0
        ;;
      *)
        xmj_backup_set_notice 'warn' '请输入 y / 0。'
        ;;
    esac
  done

  if ! xmj_maintenance_create_backup "$XMJ_SILLYTAVERN_PATH" '' '' '手动备份'; then
    xmj_render_backup_create_result \
      'failure' \
      '手动备份没有顺利完成。' \
      "${XMJ_MAINT_LAST_ERROR:-请检查当前目录与权限。}"
    return 0
  fi

  if [ -n "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
    xmj_render_backup_create_result \
      'success' \
      '手动备份已经打包完成。' \
      "${XMJ_MAINT_BACKUP_NOTE:-已生成 1 个备份压缩包。}"
    return 0
  fi

  xmj_render_backup_create_result \
    'success' \
    '当前没有可打包的备份内容。' \
    "${XMJ_MAINT_BACKUP_NOTE:-这次没有生成新的备份档。}"
  return 0
}

xmj_backup_prompt_list_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  输入 n / p / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_backup_list_page() {
  local page="${1:-1}"
  local backup_dir=''
  local page_size='0'
  local total='0'
  local total_pages='1'

  backup_dir="$(xmj_maintenance_backup_dir)"
  page_size="$(xmj_backup_page_size)"
  total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
  total_pages="$(xmj_backup_total_pages "$total" "$page_size")"
  page="$(xmj_backup_normalize_page "$page" "$total_pages")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['08']}" 'backup list' 'backup'
  printf '\n'
  xmj_render_page_intro \
    '这里会按时间从新到旧收纳现有备份。' \
    '可以先快速确认数量，再决定是否恢复或清理旧档。'
  printf '\n'
  xmj_render_fact_line '备份目录' "$(xmj_display_path "$backup_dir")"
  xmj_render_fact_line '备份总数' "$total"
  xmj_render_fact_line '当前页码' "${page}/${total_pages}"
  printf '\n'
  xmj_render_backup_archive_lines "$page" "$page_size"
  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'n' '下一页'
  xmj_render_action_item 'p' '上一页'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 n / p / 0。'
}

xmj_run_backup_list_page() {
  local input=''
  local page='1'
  local total_pages='1'

  xmj_backup_clear_notice

  while true; do
    xmj_backup_refresh_archives
    total_pages="$(xmj_backup_total_pages "${#XMJ_BACKUP_ARCHIVE_FILES[@]}" "$(xmj_backup_page_size)")"
    page="$(xmj_backup_normalize_page "$page" "$total_pages")"

    xmj_render_backup_list_page "$page"
    xmj_backup_prompt_list_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      ''|0)
        return 0
        ;;
      n|N)
        if [ "$page" -lt "$total_pages" ]; then
          page=$((page + 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是最后一页了。'
        fi
        ;;
      p|P)
        if [ "$page" -gt 1 ]; then
          page=$((page - 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是第一页了。'
        fi
        ;;
      *)
        xmj_backup_set_notice 'warn' '这里只支持输入 n / p / 0。'
        ;;
    esac
  done
}

xmj_backup_prompt_restore_select_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  备份序号 / n / p / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_backup_prompt_confirm_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  输入 y 确认 / 0 取消 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_backup_restore_page() {
  local page="${1:-1}"
  local backup_dir=''
  local page_size='0'
  local total='0'
  local total_pages='1'

  backup_dir="$(xmj_maintenance_backup_dir)"
  page_size="$(xmj_backup_page_size)"
  total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
  total_pages="$(xmj_backup_total_pages "$total" "$page_size")"
  page="$(xmj_backup_normalize_page "$page" "$total_pages")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['09']}" 'restore data' 'backup'
  printf '\n'
  xmj_render_page_intro \
    '恢复时会把备份里实际带着的内容覆盖回酒馆目录。' \
    "如果这是低版本兼容备份，猫猫只会放回 data；$(xmj_maintenance_cross_version_notice)"
  printf '\n'
  xmj_render_fact_line '酒馆目录' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_fact_line '备份总数' "$total"
  xmj_render_fact_line '当前页码' "${page}/${total_pages}"
  printf '\n'
  xmj_render_backup_archive_lines "$page" "$page_size"
  xmj_render_backup_notice
  printf '\n'

  if [ "$total" -gt 0 ]; then
    xmj_render_action_item '序号' '选择对应备份并进入恢复确认'
    xmj_render_action_item 'n' '下一页'
    xmj_render_action_item 'p' '上一页'
  fi

  xmj_render_action_item '0' '取消并返回首页'
  if [ "$total" -gt 0 ]; then
    xmj_render_action_footer '输入备份序号 / n / p / 0。'
  else
    xmj_render_action_footer '输入 0 返回首页。'
  fi
}

xmj_render_backup_restore_confirm_page() {
  local archive_file="${1:-}"
  local archive_name=''

  archive_name="$(basename "$archive_file")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['09']}" 'restore data' 'backup'
  printf '\n'
  xmj_render_page_intro \
    '这次会把所选备份覆盖恢复到当前酒馆目录。' \
    '如果这是低版本兼容备份，恢复时只会放回 data。'
  printf '\n'
  xmj_render_fact_line '备份文件' "$archive_name"
  xmj_render_fact_line '备份时间' "$(xmj_backup_archive_time_text "$archive_file")"
  xmj_render_fact_line '备份大小' "$(xmj_backup_archive_size_text "$archive_file")"
  xmj_render_fact_line '恢复到' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'y' '确认恢复这个备份'
  xmj_render_action_item '0' '取消并返回上一页'
  xmj_render_action_footer '输入 y / 0。'
}

xmj_render_backup_restore_result() {
  local result_mode="${1:-success}"
  local summary_text="${2:-恢复已完成。}"
  local detail_text="${3:-}"
  local archive_file="${4:-}"
  local card_title='恢复完成'

  if [ "$result_mode" = 'failure' ]; then
    card_title='恢复失败'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['09']}" 'restore data' 'backup'
  printf '\n'
  xmj_render_setting_card "$card_title" "$summary_text" "$detail_text"

  if [ -n "$archive_file" ]; then
    printf '\n'
    xmj_render_fact_line '恢复来源' "$(xmj_display_path "$archive_file")"
  fi

  xmj_render_fact_line '恢复到' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"

  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    printf '\n'
    printf '  %b%s%b\n' "$XMJ_WARN" "$XMJ_MAINT_BACKUP_COMPAT_NOTE" "$XMJ_RESET"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_run_backup_restore_confirm() {
  local archive_file="${1:-}"
  local input=''

  while true; do
    xmj_render_backup_restore_confirm_page "$archive_file"
    xmj_backup_prompt_confirm_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        break
        ;;
      0)
        return 1
        ;;
      *)
        xmj_backup_set_notice 'warn' '请输入 y / 0。'
        ;;
    esac
  done

  xmj_maintenance_clear_state
  XMJ_MAINT_BACKUP_DIR="$(dirname "$archive_file")"
  XMJ_MAINT_BACKUP_FILE="$archive_file"
  XMJ_MAINT_BACKUP_NAME="$(basename "$archive_file")"

  if ! xmj_maintenance_restore_backup "$XMJ_SILLYTAVERN_PATH" '' ''; then
    xmj_render_backup_restore_result \
      'failure' \
      '备份恢复没有顺利完成。' \
      "${XMJ_MAINT_LAST_ERROR:-请检查备份档与目标目录。}" \
      "$archive_file"
    return 0
  fi

  xmj_render_backup_restore_result \
    'success' \
    '备份内容已经覆盖恢复到酒馆目录。' \
    "${XMJ_MAINT_BACKUP_RESTORE_NOTE:-恢复动作已完成。}" \
    "$archive_file"
  return 0
}

xmj_run_backup_restore_page() {
  local input=''
  local page='1'
  local total='0'
  local total_pages='1'
  local selected_index='0'

  xmj_backup_clear_notice

  while true; do
    xmj_backup_refresh_archives
    total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
    total_pages="$(xmj_backup_total_pages "$total" "$(xmj_backup_page_size)")"
    page="$(xmj_backup_normalize_page "$page" "$total_pages")"

    xmj_render_backup_restore_page "$page"
    xmj_backup_prompt_restore_select_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      0)
        return 0
        ;;
      n|N)
        if [ "$page" -lt "$total_pages" ]; then
          page=$((page + 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是最后一页了。'
        fi
        ;;
      p|P)
        if [ "$page" -gt 1 ]; then
          page=$((page - 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是第一页了。'
        fi
        ;;
      ''|*[!0-9]*)
        if [ "$total" -gt 0 ]; then
          xmj_backup_set_notice 'warn' '请输入备份序号 / n / p / 0。'
        else
          xmj_backup_set_notice 'warn' '当前没有可恢复的备份，请输入 0 返回。'
        fi
        ;;
      *)
        if [ "$total" -eq 0 ]; then
          xmj_backup_set_notice 'warn' '当前没有可恢复的备份，请输入 0 返回。'
          continue
        fi

        selected_index=$((10#$input))
        if [ "$selected_index" -lt 1 ] || [ "$selected_index" -gt "$total" ]; then
          xmj_backup_set_notice 'warn' '这个备份序号超出范围了。'
          continue
        fi

        xmj_backup_clear_notice
        if xmj_run_backup_restore_confirm "${XMJ_BACKUP_ARCHIVE_FILES[$((selected_index - 1))]}"; then
          return 0
        fi
        ;;
    esac
  done
}

xmj_backup_cleanup_keep_count() {
  printf '%s' '5'
}

xmj_backup_delete_archive() {
  local archive_file="${1:-}"

  if [ -z "$archive_file" ] || [ ! -f "$archive_file" ]; then
    XMJ_MAINT_LAST_ERROR='没有找到要删除的备份档。'
    return 1
  fi

  xmj_backup_start_busy '删除备份中'
  if ! rm -f "$archive_file" 2>/dev/null; then
    xmj_backup_stop_busy
    XMJ_MAINT_LAST_ERROR="删除备份失败：$(basename "$archive_file")"
    return 1
  fi

  xmj_backup_stop_busy
  return 0
}

xmj_backup_cleanup_old_archives() {
  local keep_count="${1:-5}"
  local total='0'
  local i='0'
  local archive_file=''

  XMJ_BACKUP_CLEANUP_REMOVED='0'
  XMJ_BACKUP_CLEANUP_NOTE=''

  case "$keep_count" in
    ''|*[!0-9]*)
      keep_count='5'
      ;;
  esac

  if [ "$keep_count" -lt 1 ]; then
    keep_count='1'
  fi

  xmj_backup_refresh_archives
  total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"

  if [ "$total" -le "$keep_count" ]; then
    XMJ_BACKUP_CLEANUP_NOTE="当前共有 ${total} 个备份，少于或等于保留数量，无需清理。"
    return 0
  fi

  xmj_backup_start_busy '清理旧档中'
  for ((i = keep_count; i < total; i++)); do
    archive_file="${XMJ_BACKUP_ARCHIVE_FILES[$i]}"
    if ! rm -f "$archive_file" 2>/dev/null; then
      xmj_backup_stop_busy
      XMJ_MAINT_LAST_ERROR="删除备份失败：$(basename "$archive_file")"
      return 1
    fi

    XMJ_BACKUP_CLEANUP_REMOVED="$((XMJ_BACKUP_CLEANUP_REMOVED + 1))"
  done

  xmj_backup_stop_busy
  XMJ_BACKUP_CLEANUP_NOTE="已清理 ${XMJ_BACKUP_CLEANUP_REMOVED} 个旧备份，保留最新 ${keep_count} 个。"
  return 0
}

xmj_backup_prompt_cleanup_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  序号删除 / a 自动清理 / n / p / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_backup_cleanup_page() {
  local page="${1:-1}"
  local backup_dir=''
  local page_size='0'
  local total='0'
  local total_pages='1'
  local keep_count=''

  backup_dir="$(xmj_maintenance_backup_dir)"
  page_size="$(xmj_backup_page_size)"
  total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
  total_pages="$(xmj_backup_total_pages "$total" "$page_size")"
  page="$(xmj_backup_normalize_page "$page" "$total_pages")"
  keep_count="$(xmj_backup_cleanup_keep_count)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['10']}" 'cleanup archive' 'backup'
  printf '\n'
  xmj_render_page_intro \
    '可以按序号删除单个旧档，也可以一键只保留最近几份备份。' \
    '清理只作用于备份目录里的 zip 档案，不会修改酒馆目录本身。'
  printf '\n'
  xmj_render_fact_line '备份目录' "$(xmj_display_path "$backup_dir")"
  xmj_render_fact_line '备份总数' "$total"
  xmj_render_fact_line '自动策略' "保留最新 ${keep_count} 个"
  printf '\n'
  xmj_render_backup_archive_lines "$page" "$page_size"
  xmj_render_backup_notice
  printf '\n'

  if [ "$total" -gt 0 ]; then
    xmj_render_action_item '序号' '删除指定旧备份'
    xmj_render_action_item 'a' '自动清理，只保留最新几份'
    xmj_render_action_item 'n' '下一页'
    xmj_render_action_item 'p' '上一页'
  fi

  xmj_render_action_item '0' '返回首页'
  if [ "$total" -gt 0 ]; then
    xmj_render_action_footer '输入序号 / a / n / p / 0。'
  else
    xmj_render_action_footer '输入 0 返回首页。'
  fi
}

xmj_render_backup_cleanup_confirm_page() {
  local mode="${1:-single}"
  local archive_file="${2:-}"
  local keep_count=''
  local summary_text=''
  local detail_text=''

  keep_count="$(xmj_backup_cleanup_keep_count)"

  case "$mode" in
    auto)
      summary_text="会保留最新 ${keep_count} 个备份。"
      detail_text='更旧的 zip 备份会被直接删除，删除后不会自动恢复。'
      ;;
    *)
      summary_text="即将删除：$(basename "$archive_file")"
      detail_text='这个操作只删除备份档，不会影响酒馆目录本身。'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['10']}" 'cleanup archive' 'backup'
  printf '\n'
  xmj_render_setting_card '执行前确认' "$summary_text" "$detail_text"

  if [ "$mode" = 'single' ] && [ -n "$archive_file" ]; then
    printf '\n'
    xmj_render_fact_line '备份时间' "$(xmj_backup_archive_time_text "$archive_file")"
    xmj_render_fact_line '备份大小' "$(xmj_backup_archive_size_text "$archive_file")"
  fi

  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'y' '确认执行这次清理'
  xmj_render_action_item '0' '取消并返回上一页'
  xmj_render_action_footer '输入 y / 0。'
}

xmj_render_backup_cleanup_result() {
  local result_mode="${1:-success}"
  local summary_text="${2:-清理已完成。}"
  local detail_text="${3:-}"
  local card_title='清理完成'

  if [ "$result_mode" = 'failure' ]; then
    card_title='清理失败'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['10']}" 'cleanup archive' 'backup'
  printf '\n'
  xmj_render_setting_card "$card_title" "$summary_text" "$detail_text"
  xmj_render_page_footer '按回车返回首页'
}

xmj_run_backup_cleanup_confirm() {
  local mode="${1:-single}"
  local archive_file="${2:-}"
  local input=''

  while true; do
    xmj_render_backup_cleanup_confirm_page "$mode" "$archive_file"
    xmj_backup_prompt_confirm_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        break
        ;;
      0)
        return 1
        ;;
      *)
        xmj_backup_set_notice 'warn' '请输入 y / 0。'
        ;;
    esac
  done

  case "$mode" in
    auto)
      if ! xmj_backup_cleanup_old_archives "$(xmj_backup_cleanup_keep_count)"; then
        xmj_render_backup_cleanup_result \
          'failure' \
          '自动清理没有顺利完成。' \
          "${XMJ_MAINT_LAST_ERROR:-请检查备份目录权限。}"
        return 0
      fi

      xmj_render_backup_cleanup_result \
        'success' \
        '旧备份整理已完成。' \
        "$XMJ_BACKUP_CLEANUP_NOTE"
      return 0
      ;;
    *)
      if ! xmj_backup_delete_archive "$archive_file"; then
        xmj_render_backup_cleanup_result \
          'failure' \
          '删除旧备份没有顺利完成。' \
          "${XMJ_MAINT_LAST_ERROR:-请检查备份目录权限。}"
        return 0
      fi

      xmj_render_backup_cleanup_result \
        'success' \
        '指定旧备份已经删除。' \
        "已移除：$(basename "$archive_file")"
      return 0
      ;;
  esac
}

xmj_run_backup_cleanup_page() {
  local input=''
  local page='1'
  local total='0'
  local total_pages='1'
  local selected_index='0'

  xmj_backup_clear_notice

  while true; do
    xmj_backup_refresh_archives
    total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
    total_pages="$(xmj_backup_total_pages "$total" "$(xmj_backup_page_size)")"
    page="$(xmj_backup_normalize_page "$page" "$total_pages")"

    xmj_render_backup_cleanup_page "$page"
    xmj_backup_prompt_cleanup_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      0)
        return 0
        ;;
      a|A)
        if [ "$total" -eq 0 ]; then
          xmj_backup_set_notice 'warn' '当前没有可清理的备份。'
          continue
        fi

        xmj_backup_clear_notice
        if xmj_run_backup_cleanup_confirm 'auto' ''; then
          return 0
        fi
        ;;
      n|N)
        if [ "$page" -lt "$total_pages" ]; then
          page=$((page + 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是最后一页了。'
        fi
        ;;
      p|P)
        if [ "$page" -gt 1 ]; then
          page=$((page - 1))
          xmj_backup_clear_notice
        else
          xmj_backup_set_notice 'warn' '已经是第一页了。'
        fi
        ;;
      ''|*[!0-9]*)
        if [ "$total" -gt 0 ]; then
          xmj_backup_set_notice 'warn' '请输入备份序号 / a / n / p / 0。'
        else
          xmj_backup_set_notice 'warn' '当前没有可清理的备份，请输入 0 返回。'
        fi
        ;;
      *)
        if [ "$total" -eq 0 ]; then
          xmj_backup_set_notice 'warn' '当前没有可清理的备份，请输入 0 返回。'
          continue
        fi

        selected_index=$((10#$input))
        if [ "$selected_index" -lt 1 ] || [ "$selected_index" -gt "$total" ]; then
          xmj_backup_set_notice 'warn' '这个备份序号超出范围了。'
          continue
        fi

        xmj_backup_clear_notice
        if xmj_run_backup_cleanup_confirm 'single' "${XMJ_BACKUP_ARCHIVE_FILES[$((selected_index - 1))]}"; then
          return 0
        fi
        ;;
    esac
  done
}

xmj_dependency_timestamp() {
  local stamp=''

  stamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$stamp" ]; then
    stamp='unknown-time'
  fi

  printf '%s' "$stamp"
}

xmj_dependency_append_detail() {
  local base_text="${1:-}"
  local extra_text="${2:-}"

  if [ -z "$extra_text" ]; then
    printf '%s' "$base_text"
    return 0
  fi

  if [ -z "$base_text" ]; then
    printf '%s' "$extra_text"
    return 0
  fi

  printf '%s %s' "$base_text" "$extra_text"
}

xmj_dependency_join_parts() {
  local joined=''
  local item=''

  for item in "$@"; do
    if [ -z "$item" ]; then
      continue
    fi

    if [ -n "$joined" ]; then
      joined="${joined}；"
    fi
    joined="${joined}${item}"
  done

  printf '%s' "$joined"
}

xmj_dependency_bool_text() {
  local flag="${1:-0}"
  local true_text="${2:-是}"
  local false_text="${3:-否}"

  if [ "$flag" = '1' ]; then
    printf '%s' "$true_text"
    return 0
  fi

  printf '%s' "$false_text"
}

xmj_dependency_capture_first_line() {
  local output=''

  output="$("$@" 2>/dev/null || true)"
  output="${output%%$'\n'*}"

  printf '%s' "$output"
}

xmj_dependency_reset_state() {
  XMJ_DEP_LOG_FILE=''
  XMJ_DEP_NOTICE=''
  XMJ_DEP_NOTICE_KIND='info'
  XMJ_DEP_LAST_ERROR=''
  XMJ_DEP_CHECK_LEVEL='info'
  XMJ_DEP_CHECK_SUMMARY=''
  XMJ_DEP_CHECK_DETAIL=''
  XMJ_DEP_CHECK_RECOMMEND=''
  XMJ_DEP_REPO_EXISTS='0'
  XMJ_DEP_REPO_GIT='0'
  XMJ_DEP_PACKAGE_JSON='0'
  XMJ_DEP_NODE_MODULES='0'
  XMJ_DEP_BACKUP_DIR_OK='0'
  XMJ_DEP_LOG_DIR_OK='0'
  XMJ_DEP_GIT_STATE='missing'
  XMJ_DEP_NODE_STATE='missing'
  XMJ_DEP_NPM_STATE='missing'
  XMJ_DEP_PYTHON_STATE='missing'
  XMJ_DEP_ZIP_STATE='missing'
  XMJ_DEP_UNZIP_STATE='missing'
  XMJ_DEP_PKG_STATE='missing'
  XMJ_DEP_GIT_VERSION='未检测到'
  XMJ_DEP_NODE_VERSION='未检测到'
  XMJ_DEP_NPM_VERSION='未检测到'
  XMJ_DEP_PYTHON_VERSION='未检测到'
  XMJ_DEP_ZIP_VERSION='未检测到'
  XMJ_DEP_UNZIP_VERSION='未检测到'
  XMJ_DEP_PKG_VERSION='未检测到'
  XMJ_DEP_PYTHON_CMD=''
  XMJ_DEP_CURRENT_VERSION='未识别'
  XMJ_DEP_CURRENT_BRANCH='未识别'
  XMJ_DEP_CURRENT_COMMIT='未识别'
  XMJ_DEP_REMOTE_URL='未配置'
  XMJ_DEP_UPSTREAM='未配置'
  XMJ_DEP_AHEAD='0'
  XMJ_DEP_BEHIND='0'
  XMJ_DEP_DETACHED='0'
  XMJ_DEP_WORKTREE_DIRTY='0'
  XMJ_DEP_WORKTREE_TEXT='未检测'
  XMJ_DEP_REPAIR_BRANCH=''
  XMJ_DEP_PACKAGE_INSTALL_NOTE=''
  XMJ_DEP_DIRECTORY_NOTE=''
  XMJ_DEP_REPO_REPAIR_NOTE=''
  XMJ_DEP_PROJECT_DEP_NOTE=''
  declare -ga XMJ_DEP_MISSING_PACKAGES=()
}

xmj_dependency_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_DEP_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_dependency_timestamp)" "$line" >>"$XMJ_DEP_LOG_FILE"
}

xmj_dependency_prepare_log_file() {
  local prefix="${1:-dependency}"
  local stamp=''

  if [ -z "${XMJ_LOG_DIR:-}" ]; then
    XMJ_LOG_DIR="${XMJ_ROOT_DIR:-.}/logs"
  fi

  if ! mkdir -p "$XMJ_LOG_DIR" 2>/dev/null; then
    XMJ_DEP_LAST_ERROR='无法创建日志目录。'
    return 1
  fi

  stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stamp" ]; then
    stamp='manual'
  fi

  XMJ_DEP_LOG_FILE="$XMJ_LOG_DIR/${prefix}-${stamp}.log"
  if ! : >"$XMJ_DEP_LOG_FILE" 2>/dev/null; then
    XMJ_DEP_LAST_ERROR="无法创建日志文件：$XMJ_DEP_LOG_FILE"
    return 1
  fi

  return 0
}

xmj_dependency_notice_color() {
  case "${1:-info}" in
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    success)
      printf '%s' "$XMJ_CREAM"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_dependency_clear_notice() {
  XMJ_DEP_NOTICE=''
  XMJ_DEP_NOTICE_KIND='info'
}

xmj_dependency_set_notice() {
  XMJ_DEP_NOTICE_KIND="${1:-info}"
  XMJ_DEP_NOTICE="${2:-}"
}

xmj_dependency_render_notice() {
  local notice_text="${XMJ_DEP_NOTICE:-}"
  local notice_color=''

  if [ -z "$notice_text" ]; then
    return 0
  fi

  notice_color="$(xmj_dependency_notice_color "${XMJ_DEP_NOTICE_KIND:-info}")"
  printf '\n'
  printf '  %b%s%b\n' "$notice_color" "$notice_text" "$XMJ_RESET"
}

xmj_dependency_find_repair_branch() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local remote_head=''
  local candidate=''
  local branch=''
  local seen='|'
  local shell_log=''
  local -a candidates=()

  shell_log="$(xmj_maintenance_shell_log_target "${XMJ_DEP_LOG_FILE:-}")"

  remote_head="$(git -C "$repo_path" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>>"$shell_log" || true)"
  remote_head="${remote_head#origin/}"
  if [ -n "$remote_head" ]; then
    candidates+=("$remote_head")
    seen="${seen}${remote_head}|"
  fi

  for candidate in release main master; do
    case "$seen" in
      *"|$candidate|"*)
        ;;
      *)
        candidates+=("$candidate")
        seen="${seen}${candidate}|"
        ;;
    esac
  done

  for branch in "${candidates[@]}"; do
    if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$branch" 2>>"$shell_log" \
      || git -C "$repo_path" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>>"$shell_log"; then
      printf '%s' "$branch"
      return 0
    fi
  done

  while IFS= read -r branch || [ -n "$branch" ]; do
    branch="${branch#origin/}"
    case "$branch" in
      ''|HEAD)
        continue
        ;;
    esac

    case "$seen" in
      *"|$branch|"*)
        continue
        ;;
    esac

    printf '%s' "$branch"
    return 0
  done < <(git -C "$repo_path" for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin 2>>"$shell_log")

  return 1
}

xmj_dependency_collect_missing_packages() {
  declare -ga XMJ_DEP_MISSING_PACKAGES=()

  if [ "${XMJ_DEP_GIT_STATE:-missing}" != 'ok' ]; then
    XMJ_DEP_MISSING_PACKAGES+=('git')
  fi

  if [ "${XMJ_DEP_NODE_STATE:-missing}" != 'ok' ] || [ "${XMJ_DEP_NPM_STATE:-missing}" != 'ok' ]; then
    XMJ_DEP_MISSING_PACKAGES+=('nodejs-lts')
  fi

  if [ "${XMJ_DEP_ZIP_STATE:-missing}" != 'ok' ]; then
    XMJ_DEP_MISSING_PACKAGES+=('zip')
  fi

  if [ "${XMJ_DEP_UNZIP_STATE:-missing}" != 'ok' ]; then
    XMJ_DEP_MISSING_PACKAGES+=('unzip')
  fi
}

xmj_dependency_missing_packages_text() {
  local joined=''
  local item=''

  for item in "${XMJ_DEP_MISSING_PACKAGES[@]}"; do
    if [ -n "$joined" ]; then
      joined="${joined}、"
    fi
    joined="${joined}${item}"
  done

  printf '%s' "$joined"
}

xmj_dependency_finalize_check() {
  local detail_text=''
  local recommend_text=''
  local -a blockers=()
  local -a warnings=()

  if [ "${XMJ_DEP_REPO_EXISTS:-0}" != '1' ]; then
    blockers+=('未找到 SillyTavern 目录')
  fi

  if [ "${XMJ_DEP_GIT_STATE:-missing}" != 'ok' ]; then
    blockers+=('未检测到 git')
  fi

  if [ "${XMJ_DEP_NODE_STATE:-missing}" != 'ok' ] || [ "${XMJ_DEP_NPM_STATE:-missing}" != 'ok' ]; then
    blockers+=('未检测到 node / npm')
  fi

  if [ "${XMJ_DEP_REPO_EXISTS:-0}" = '1' ] && [ "${XMJ_DEP_PACKAGE_JSON:-0}" != '1' ]; then
    blockers+=('目录里未发现 package.json')
  fi

  if [ "${XMJ_DEP_BACKUP_DIR_OK:-0}" != '1' ]; then
    warnings+=('备份目录当前未就绪')
  fi

  if [ "${XMJ_DEP_LOG_DIR_OK:-0}" != '1' ]; then
    warnings+=('日志目录当前未就绪')
  fi

  if [ "${XMJ_DEP_ZIP_STATE:-missing}" != 'ok' ] || [ "${XMJ_DEP_UNZIP_STATE:-missing}" != 'ok' ]; then
    warnings+=('zip / unzip 尚未补齐')
  fi

  if [ "${XMJ_DEP_REPO_GIT:-0}" = '1' ] && [ "${XMJ_DEP_DETACHED:-0}" = '1' ]; then
    warnings+=('仓库当前处于 detached HEAD')
  fi

  if [ "${XMJ_DEP_PACKAGE_JSON:-0}" = '1' ] && [ "${XMJ_DEP_NODE_MODULES:-0}" != '1' ]; then
    warnings+=('node_modules 尚未准备好')
  fi

  if [ "${XMJ_DEP_WORKTREE_DIRTY:-0}" = '1' ]; then
    warnings+=('检测到本地改动')
  fi

  if [ "${#blockers[@]}" -gt 0 ]; then
    XMJ_DEP_CHECK_LEVEL='failure'
    XMJ_DEP_CHECK_SUMMARY='当前环境还不能直接执行酒馆维护。'
    detail_text="$(xmj_dependency_join_parts "${blockers[@]}" "${warnings[@]}")"
    recommend_text='建议先执行 11 安装依赖或 13 异常修复。'
  elif [ "${#warnings[@]}" -gt 0 ]; then
    XMJ_DEP_CHECK_LEVEL='warn'
    XMJ_DEP_CHECK_SUMMARY='环境基本可用，但还有几项建议先整理。'
    detail_text="$(xmj_dependency_join_parts "${warnings[@]}")"
    recommend_text='如需统一整理，可进入 13 异常修复。'
  else
    XMJ_DEP_CHECK_LEVEL='success'
    XMJ_DEP_CHECK_SUMMARY='环境检查通过，主要依赖已经就绪。'
    detail_text='Git、Node.js、npm、备份目录和日志目录都已准备好。'
    recommend_text='当前可以直接使用更新、切换版本和备份流程。'
  fi

  XMJ_DEP_CHECK_DETAIL="$detail_text"
  XMJ_DEP_CHECK_RECOMMEND="$recommend_text"
}

xmj_dependency_collect_context() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local shell_log=''
  local repo_flag=''
  local worktree_state=''
  local counts=''
  local count_left=''
  local count_right=''

  shell_log="$(xmj_maintenance_shell_log_target "${XMJ_DEP_LOG_FILE:-}")"

  XMJ_DEP_REPO_EXISTS='0'
  XMJ_DEP_REPO_GIT='0'
  XMJ_DEP_PACKAGE_JSON='0'
  XMJ_DEP_NODE_MODULES='0'
  XMJ_DEP_BACKUP_DIR_OK='0'
  XMJ_DEP_LOG_DIR_OK='0'
  XMJ_DEP_GIT_STATE='missing'
  XMJ_DEP_NODE_STATE='missing'
  XMJ_DEP_NPM_STATE='missing'
  XMJ_DEP_PYTHON_STATE='missing'
  XMJ_DEP_ZIP_STATE='missing'
  XMJ_DEP_UNZIP_STATE='missing'
  XMJ_DEP_PKG_STATE='missing'
  XMJ_DEP_GIT_VERSION='未检测到'
  XMJ_DEP_NODE_VERSION='未检测到'
  XMJ_DEP_NPM_VERSION='未检测到'
  XMJ_DEP_PYTHON_VERSION='未检测到'
  XMJ_DEP_ZIP_VERSION='未检测到'
  XMJ_DEP_UNZIP_VERSION='未检测到'
  XMJ_DEP_PKG_VERSION='未检测到'
  XMJ_DEP_PYTHON_CMD=''
  XMJ_DEP_CURRENT_VERSION='未识别'
  XMJ_DEP_CURRENT_BRANCH='未识别'
  XMJ_DEP_CURRENT_COMMIT='未识别'
  XMJ_DEP_REMOTE_URL='未配置'
  XMJ_DEP_UPSTREAM='未配置'
  XMJ_DEP_AHEAD='0'
  XMJ_DEP_BEHIND='0'
  XMJ_DEP_DETACHED='0'
  XMJ_DEP_WORKTREE_DIRTY='0'
  XMJ_DEP_WORKTREE_TEXT='未检测'
  XMJ_DEP_REPAIR_BRANCH=''

  if [ -n "${XMJ_BACKUP_DIR:-}" ] && [ -d "${XMJ_BACKUP_DIR:-}" ]; then
    XMJ_DEP_BACKUP_DIR_OK='1'
  fi

  if [ -n "${XMJ_LOG_DIR:-}" ] && [ -d "${XMJ_LOG_DIR:-}" ]; then
    XMJ_DEP_LOG_DIR_OK='1'
  fi

  if command -v git >/dev/null 2>&1; then
    XMJ_DEP_GIT_STATE='ok'
    XMJ_DEP_GIT_VERSION="$(xmj_dependency_capture_first_line git --version)"
  fi

  if command -v node >/dev/null 2>&1; then
    XMJ_DEP_NODE_STATE='ok'
    XMJ_DEP_NODE_VERSION="$(xmj_dependency_capture_first_line node -v)"
  fi

  if command -v npm >/dev/null 2>&1; then
    XMJ_DEP_NPM_STATE='ok'
    XMJ_DEP_NPM_VERSION="$(xmj_dependency_capture_first_line npm -v)"
  fi

  if command -v python3 >/dev/null 2>&1; then
    XMJ_DEP_PYTHON_STATE='ok'
    XMJ_DEP_PYTHON_CMD='python3'
    XMJ_DEP_PYTHON_VERSION="$(xmj_dependency_capture_first_line python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    XMJ_DEP_PYTHON_STATE='ok'
    XMJ_DEP_PYTHON_CMD='python'
    XMJ_DEP_PYTHON_VERSION="$(xmj_dependency_capture_first_line python --version)"
  fi

  if command -v zip >/dev/null 2>&1; then
    XMJ_DEP_ZIP_STATE='ok'
    XMJ_DEP_ZIP_VERSION="$(xmj_dependency_capture_first_line zip -v)"
  fi

  if command -v unzip >/dev/null 2>&1; then
    XMJ_DEP_UNZIP_STATE='ok'
    XMJ_DEP_UNZIP_VERSION="$(xmj_dependency_capture_first_line unzip -v)"
  fi

  if command -v pkg >/dev/null 2>&1; then
    XMJ_DEP_PKG_STATE='ok'
    XMJ_DEP_PKG_VERSION='pkg 已检测'
  fi

  if [ -n "$repo_path" ] && [ -d "$repo_path" ]; then
    XMJ_DEP_REPO_EXISTS='1'

    if [ -f "$repo_path/package.json" ]; then
      XMJ_DEP_PACKAGE_JSON='1'
    fi

    if [ -d "$repo_path/node_modules" ]; then
      XMJ_DEP_NODE_MODULES='1'
    fi
  fi

  if [ "${XMJ_DEP_REPO_EXISTS:-0}" = '1' ] && [ "${XMJ_DEP_GIT_STATE:-missing}" = 'ok' ]; then
    repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$shell_log" || true)"
    if [ "$repo_flag" = 'true' ]; then
      XMJ_DEP_REPO_GIT='1'
      XMJ_DEP_CURRENT_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$shell_log")"
      XMJ_DEP_CURRENT_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$shell_log" || true)"
      if [ -z "$XMJ_DEP_CURRENT_COMMIT" ]; then
        XMJ_DEP_CURRENT_COMMIT='未识别'
      fi

      XMJ_DEP_CURRENT_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$shell_log" || true)"
      if [ -z "$XMJ_DEP_CURRENT_BRANCH" ]; then
        XMJ_DEP_CURRENT_BRANCH='detached HEAD'
        XMJ_DEP_DETACHED='1'
        XMJ_DEP_REPAIR_BRANCH="$(xmj_dependency_find_repair_branch || true)"
      fi

      XMJ_DEP_REMOTE_URL="$(git -C "$repo_path" remote get-url origin 2>>"$shell_log" || true)"
      if [ -z "$XMJ_DEP_REMOTE_URL" ]; then
        XMJ_DEP_REMOTE_URL='未配置'
      fi

      XMJ_DEP_UPSTREAM="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>>"$shell_log" || true)"
      if [ -z "$XMJ_DEP_UPSTREAM" ]; then
        XMJ_DEP_UPSTREAM='未配置'
      else
        counts="$(git -C "$repo_path" rev-list --left-right --count "${XMJ_DEP_UPSTREAM}...HEAD" 2>>"$shell_log" || true)"
        count_left="${counts%%[[:space:]]*}"
        count_right="${counts##*[[:space:]]}"
        case "$count_left" in
          ''|*[!0-9]*)
            count_left='0'
            ;;
        esac
        case "$count_right" in
          ''|*[!0-9]*)
            count_right='0'
            ;;
        esac
        XMJ_DEP_BEHIND="$count_left"
        XMJ_DEP_AHEAD="$count_right"
      fi

      worktree_state="$(git -C "$repo_path" status --porcelain 2>>"$shell_log" || true)"
      if [ -n "$worktree_state" ]; then
        XMJ_DEP_WORKTREE_DIRTY='1'
        XMJ_DEP_WORKTREE_TEXT='存在本地改动'
      else
        XMJ_DEP_WORKTREE_TEXT='工作区干净'
      fi
    else
      XMJ_DEP_WORKTREE_TEXT='当前目录不是 Git 仓库'
    fi
  fi

  xmj_dependency_collect_missing_packages
  xmj_dependency_finalize_check
}

xmj_dependency_archive_state_text() {
  if [ "${XMJ_DEP_ZIP_STATE:-missing}" = 'ok' ] && [ "${XMJ_DEP_UNZIP_STATE:-missing}" = 'ok' ]; then
    printf '%s' 'zip / unzip 已检测'
    return 0
  fi

  printf '%s' 'zip / unzip 未齐'
}

xmj_dependency_action_label() {
  case "${1:-install}" in
    repair)
      printf '%s' "${XMJ_MENU_LABEL['13']}"
      ;;
    *)
      printf '%s' "${XMJ_MENU_LABEL['11']}"
      ;;
  esac
}

xmj_dependency_action_phrase() {
  case "${1:-install}" in
    repair)
      printf '%s' 'repair env'
      ;;
    *)
      printf '%s' 'install deps'
      ;;
  esac
}

xmj_dependency_stage_order() {
  case "${1:-prepare}" in
    prepare) printf '%s' '1' ;;
    env) printf '%s' '2' ;;
    packages) printf '%s' '3' ;;
    repo) printf '%s' '4' ;;
    deps) printf '%s' '5' ;;
    done) printf '%s' '6' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_dependency_stage_label() {
  case "${1:-prepare}" in
    prepare) printf '%s' '准备中' ;;
    env) printf '%s' '扫描环境' ;;
    packages) printf '%s' '补齐系统依赖' ;;
    repo) printf '%s' '修复仓库状态' ;;
    deps) printf '%s' '整理项目依赖' ;;
    done) printf '%s' '完成' ;;
    *) printf '%s' '处理中' ;;
  esac
}

xmj_render_dependency_stage_line() {
  local stage="${1:-prepare}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local stage_order='0'
  local current_order='0'
  local marker='·'
  local state_text='等待中'
  local color="$XMJ_MIST"

  stage_order="$(xmj_dependency_stage_order "$stage")"
  current_order="$(xmj_dependency_stage_order "$current_stage")"

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
    "$XMJ_WHITE" "$(xmj_dependency_stage_label "$stage")" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$color" "$state_text" "$XMJ_RESET"
}

xmj_render_dependency_stage_group() {
  local action="${1:-install}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"

  xmj_render_dependency_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_dependency_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_dependency_stage_line 'packages' "$current_stage" "$stage_mode"

  if [ "$action" = 'repair' ]; then
    xmj_render_dependency_stage_line 'repo' "$current_stage" "$stage_mode"
  fi

  xmj_render_dependency_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_dependency_stage_line 'done' "$current_stage" "$stage_mode"
}

xmj_render_dependency_progress() {
  local action="${1:-install}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local headline="${4:-准备中}"
  local detail_text="${5:-猫猫正在整理依赖环境。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_dependency_action_label "$action")" "$(xmj_dependency_action_phrase "$action")" 'dependency'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ %s进度%b\n' "$XMJ_PINK" "$(xmj_dependency_action_label "$action")" "$XMJ_RESET"
  xmj_render_dependency_stage_group "$action" "$current_stage" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_dependency_result() {
  local action="${1:-install}"
  local result_mode="${2:-success}"
  local current_stage="${3:-done}"
  local summary_text="${4:-已完成。}"
  local detail_text="${5:-}"
  local result_title='已完成'
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='执行失败'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_dependency_action_label "$action")" "$(xmj_dependency_action_phrase "$action")" 'dependency'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ %s进度%b\n' "$XMJ_PINK" "$(xmj_dependency_action_label "$action")" "$XMJ_RESET"
  xmj_render_dependency_stage_group "$action" "$current_stage" "$stage_mode"

  if [ -n "${XMJ_DEP_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_DEP_LOG_FILE")"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_dependency_render_environment_snapshot() {
  xmj_render_fact_line '酒馆目录' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_fact_line '目录状态' "$(xmj_dependency_bool_text "${XMJ_DEP_REPO_EXISTS:-0}" '已找到' '未找到')"
  xmj_render_fact_line 'Git' "${XMJ_DEP_GIT_VERSION:-未检测到}"
  xmj_render_fact_line 'Node.js' "${XMJ_DEP_NODE_VERSION:-未检测到}"
  xmj_render_fact_line 'npm' "${XMJ_DEP_NPM_VERSION:-未检测到}"
  xmj_render_fact_line '压缩工具' "$(xmj_dependency_archive_state_text)"
  xmj_render_fact_line 'package.json' "$(xmj_dependency_bool_text "${XMJ_DEP_PACKAGE_JSON:-0}" '已找到' '未找到')"
  xmj_render_fact_line 'node_modules' "$(xmj_dependency_bool_text "${XMJ_DEP_NODE_MODULES:-0}" '已存在' '未安装')"
  xmj_render_fact_line '备份目录' "$(xmj_dependency_bool_text "${XMJ_DEP_BACKUP_DIR_OK:-0}" '已就绪' '未就绪')"
  xmj_render_fact_line '日志目录' "$(xmj_dependency_bool_text "${XMJ_DEP_LOG_DIR_OK:-0}" '已就绪' '未就绪')"
}

xmj_render_dependency_check_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['12']}" 'environment check' 'dependency'
  printf '\n'
  xmj_render_setting_card '检查结果' "${XMJ_DEP_CHECK_SUMMARY:-暂未检查。}" "${XMJ_DEP_CHECK_DETAIL:-}"
  printf '\n'
  xmj_dependency_render_environment_snapshot

  if [ -n "${XMJ_DEP_CHECK_RECOMMEND:-}" ]; then
    printf '\n'
    xmj_render_page_intro "${XMJ_DEP_CHECK_RECOMMEND}" ''
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_dependency_status_page() {
  local relation_text='未配置上游'
  local recommend_text=''

  if [ "${XMJ_DEP_REPO_GIT:-0}" = '1' ] && [ "${XMJ_DEP_UPSTREAM:-未配置}" != '未配置' ]; then
    relation_text="ahead ${XMJ_DEP_AHEAD:-0} / behind ${XMJ_DEP_BEHIND:-0}"
  fi

  if [ "${XMJ_DEP_DETACHED:-0}" = '1' ] && [ -n "${XMJ_DEP_REPAIR_BRANCH:-}" ]; then
    recommend_text="可通过 13 异常修复自动切回 ${XMJ_DEP_REPAIR_BRANCH} 分支。"
  elif [ "${XMJ_DEP_DETACHED:-0}" = '1' ]; then
    recommend_text='当前仓库处于 detached HEAD，建议先手动确认目标分支。'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['14']}" 'version status' 'dependency'
  printf '\n'
  xmj_render_setting_card '当前仓库状态' "${XMJ_DEP_CURRENT_VERSION:-未识别}" "${XMJ_DEP_WORKTREE_TEXT:-未检测}"
  printf '\n'
  xmj_render_fact_line '酒馆目录' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_fact_line '仓库状态' "$(xmj_dependency_bool_text "${XMJ_DEP_REPO_GIT:-0}" 'Git 仓库' '普通目录')"
  xmj_render_fact_line '当前分支' "${XMJ_DEP_CURRENT_BRANCH:-未识别}"
  xmj_render_fact_line '当前提交' "${XMJ_DEP_CURRENT_COMMIT:-未识别}"
  xmj_render_fact_line '版本标识' "${XMJ_DEP_CURRENT_VERSION:-未识别}"
  xmj_render_fact_line '上游分支' "${XMJ_DEP_UPSTREAM:-未配置}"
  xmj_render_fact_line '同步关系' "$relation_text"
  xmj_render_fact_line 'origin' "${XMJ_DEP_REMOTE_URL:-未配置}"
  xmj_render_fact_line 'detached HEAD' "$(xmj_dependency_bool_text "${XMJ_DEP_DETACHED:-0}" '是' '否')"
  xmj_render_fact_line 'Node.js' "${XMJ_DEP_NODE_VERSION:-未检测到}"
  xmj_render_fact_line 'npm' "${XMJ_DEP_NPM_VERSION:-未检测到}"

  if [ -n "$recommend_text" ]; then
    printf '\n'
    xmj_render_page_intro "$recommend_text" ''
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_dependency_install_confirm_page() {
  local system_text=''
  local project_text=''

  if [ "${#XMJ_DEP_MISSING_PACKAGES[@]}" -gt 0 ]; then
    system_text="会补齐：$(xmj_dependency_missing_packages_text)"
  else
    system_text='当前 git / node / npm / zip / unzip 已检测齐。'
  fi

  if [ "${XMJ_DEP_PACKAGE_JSON:-0}" = '1' ]; then
    project_text='确认后会进入酒馆目录执行 npm install。'
  else
    project_text='当前目录里未发现 package.json，本次只会整理系统依赖。'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['11']}" 'install deps' 'dependency'
  printf '\n'
  xmj_render_setting_card '执行前确认' "$system_text" "$project_text"
  printf '\n'
  xmj_dependency_render_environment_snapshot
  xmj_dependency_render_notice
  printf '\n'
  xmj_render_action_item 'y' '开始安装 / 重新整理依赖'
  xmj_render_action_item '0' '取消并返回首页'
  xmj_render_action_footer '输入 y / 0'
}

xmj_render_dependency_repair_confirm_page() {
  local issue_text=''
  local repair_text=''

  issue_text="${XMJ_DEP_CHECK_DETAIL:-当前没有检测到明确异常。}"
  if [ "${XMJ_DEP_DETACHED:-0}" = '1' ] && [ -n "${XMJ_DEP_REPAIR_BRANCH:-}" ]; then
    repair_text="会尝试切回 ${XMJ_DEP_REPAIR_BRANCH} 分支，并重新整理项目依赖。"
  else
    repair_text='会补齐目录与系统依赖，并在可行时重新整理项目依赖。'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['13']}" 'repair env' 'dependency'
  printf '\n'
  xmj_render_setting_card '执行前确认' "${XMJ_DEP_CHECK_SUMMARY:-准备开始异常修复。}" "$issue_text"
  printf '\n'
  xmj_render_page_intro "$repair_text" ''
  printf '\n'
  xmj_dependency_render_environment_snapshot
  xmj_dependency_render_notice
  printf '\n'
  xmj_render_action_item 'y' '开始自动修复常见异常'
  xmj_render_action_item '0' '取消并返回首页'
  xmj_render_action_footer '输入 y / 0'
}

xmj_dependency_prompt_confirm_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  y 开始 / 0 返回 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_dependency_ensure_runtime_dirs() {
  local joined=''
  local -a created=()

  if [ -n "${XMJ_BACKUP_DIR:-}" ] && [ ! -d "${XMJ_BACKUP_DIR:-}" ]; then
    if ! mkdir -p "${XMJ_BACKUP_DIR}" 2>/dev/null; then
      XMJ_DEP_LAST_ERROR="无法创建备份目录：${XMJ_BACKUP_DIR}"
      return 1
    fi
    created+=('备份目录')
  fi

  if [ -n "${XMJ_LOG_DIR:-}" ] && [ ! -d "${XMJ_LOG_DIR:-}" ]; then
    if ! mkdir -p "${XMJ_LOG_DIR}" 2>/dev/null; then
      XMJ_DEP_LAST_ERROR="无法创建日志目录：${XMJ_LOG_DIR}"
      return 1
    fi
    created+=('日志目录')
  fi

  if [ "${#created[@]}" -eq 0 ]; then
    XMJ_DEP_DIRECTORY_NOTE='备份目录和日志目录都已就绪。'
  else
    joined="$(xmj_dependency_join_parts "${created[@]}")"
    XMJ_DEP_DIRECTORY_NOTE="已补齐 ${joined}。"
  fi

  xmj_dependency_log_line "$XMJ_DEP_DIRECTORY_NOTE"
  return 0
}

xmj_dependency_install_termux_packages() {
  local shell_log=''
  local package_text=''

  shell_log="$(xmj_maintenance_shell_log_target "${XMJ_DEP_LOG_FILE:-}")"
  xmj_dependency_collect_missing_packages

  if [ "${#XMJ_DEP_MISSING_PACKAGES[@]}" -eq 0 ]; then
    XMJ_DEP_PACKAGE_INSTALL_NOTE='系统依赖已经齐了，本次无需额外安装。'
    xmj_dependency_log_line "$XMJ_DEP_PACKAGE_INSTALL_NOTE"
    return 0
  fi

  package_text="$(xmj_dependency_missing_packages_text)"
  if ! command -v pkg >/dev/null 2>&1; then
    XMJ_DEP_LAST_ERROR="缺少 ${package_text}，且当前环境未检测到 pkg，无法自动安装。"
    return 1
  fi

  xmj_dependency_log_line "开始安装 Termux 包：${package_text}"
  if ! pkg install -y "${XMJ_DEP_MISSING_PACKAGES[@]}" >>"$shell_log" 2>&1; then
    XMJ_DEP_LAST_ERROR="自动安装 ${package_text} 失败，可温和查看日志。"
    return 1
  fi

  XMJ_DEP_PACKAGE_INSTALL_NOTE="已补齐 ${package_text}。"
  xmj_dependency_log_line "$XMJ_DEP_PACKAGE_INSTALL_NOTE"
  return 0
}

xmj_dependency_sync_project_dependencies() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local shell_log=''

  shell_log="$(xmj_maintenance_shell_log_target "${XMJ_DEP_LOG_FILE:-}")"

  if [ "${XMJ_DEP_REPO_EXISTS:-0}" != '1' ]; then
    XMJ_DEP_PROJECT_DEP_NOTE='当前未找到酒馆目录，已跳过 npm install。'
    xmj_dependency_log_line "$XMJ_DEP_PROJECT_DEP_NOTE"
    return 0
  fi

  if [ "${XMJ_DEP_PACKAGE_JSON:-0}" != '1' ]; then
    XMJ_DEP_PROJECT_DEP_NOTE='当前目录里未发现 package.json，已跳过 npm install。'
    xmj_dependency_log_line "$XMJ_DEP_PROJECT_DEP_NOTE"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    XMJ_DEP_LAST_ERROR='未检测到 npm，无法执行 npm install。'
    return 1
  fi

  xmj_dependency_log_line '开始执行 npm install。'
  if ! (
    cd "$repo_path" || exit 1
    npm install --no-audit --no-fund
  ) >>"$shell_log" 2>&1; then
    XMJ_DEP_LAST_ERROR='npm install 执行失败，可温和查看日志。'
    return 1
  fi

  XMJ_DEP_PROJECT_DEP_NOTE='项目依赖已完成 npm install。'
  xmj_dependency_log_line "$XMJ_DEP_PROJECT_DEP_NOTE"
  return 0
}

xmj_dependency_repair_repo_state() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local shell_log=''
  local target_branch=''

  shell_log="$(xmj_maintenance_shell_log_target "${XMJ_DEP_LOG_FILE:-}")"

  if [ "${XMJ_DEP_REPO_EXISTS:-0}" != '1' ]; then
    XMJ_DEP_LAST_ERROR='未找到 SillyTavern 目录，无法执行仓库状态修复。'
    return 1
  fi

  if [ "${XMJ_DEP_REPO_GIT:-0}" != '1' ]; then
    XMJ_DEP_LAST_ERROR='当前目录不是 Git 仓库，暂时无法自动修复分支状态。'
    return 1
  fi

  if [ "${XMJ_DEP_DETACHED:-0}" != '1' ]; then
    XMJ_DEP_REPO_REPAIR_NOTE='当前分支状态正常，无需额外修复。'
    xmj_dependency_log_line "$XMJ_DEP_REPO_REPAIR_NOTE"
    return 0
  fi

  target_branch="${XMJ_DEP_REPAIR_BRANCH:-}"
  if [ -z "$target_branch" ]; then
    XMJ_DEP_LAST_ERROR='当前仓库处于 detached HEAD，且没有找到可自动切回的分支。'
    return 1
  fi

  xmj_dependency_log_line "开始修复 detached HEAD：${target_branch}"
  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$target_branch" 2>>"$shell_log"; then
    if ! git -C "$repo_path" checkout "$target_branch" >>"$shell_log" 2>&1; then
      XMJ_DEP_LAST_ERROR="切回 ${target_branch} 分支失败，可温和查看日志。"
      return 1
    fi
  elif git -C "$repo_path" show-ref --verify --quiet "refs/remotes/origin/$target_branch" 2>>"$shell_log"; then
    if ! git -C "$repo_path" checkout -b "$target_branch" --track "origin/$target_branch" >>"$shell_log" 2>&1; then
      XMJ_DEP_LAST_ERROR="创建并切回 ${target_branch} 分支失败，可温和查看日志。"
      return 1
    fi
  else
    XMJ_DEP_LAST_ERROR="没有找到 ${target_branch} 对应的本地或远程分支。"
    return 1
  fi

  XMJ_DEP_REPO_REPAIR_NOTE="已自动切回 ${target_branch} 分支。"
  xmj_dependency_log_line "$XMJ_DEP_REPO_REPAIR_NOTE"
  return 0
}

xmj_dependency_install_result_summary() {
  if [ "${XMJ_DEP_REPO_EXISTS:-0}" != '1' ]; then
    printf '%s' '系统依赖已安装，酒馆目录仍待确认。'
    return 0
  fi

  if [ "${XMJ_DEP_PACKAGE_JSON:-0}" != '1' ]; then
    printf '%s' '系统依赖已安装，当前目录仍需确认是否为酒馆仓库。'
    return 0
  fi

  if [ -n "${XMJ_DEP_PROJECT_DEP_NOTE:-}" ] && [ "${XMJ_DEP_PACKAGE_JSON:-0}" = '1' ]; then
    printf '%s' '依赖安装已完成。'
    return 0
  fi

  printf '%s' '系统依赖整理已完成。'
}

xmj_dependency_repair_result_summary() {
  if [ "${XMJ_DEP_CHECK_LEVEL:-info}" = 'failure' ]; then
    printf '%s' '异常修复执行后仍有阻塞项。'
    return 0
  fi

  printf '%s' '常见异常已整理完成。'
}

xmj_run_dependency_check_page() {
  xmj_dependency_reset_state
  xmj_dependency_collect_context
  xmj_render_dependency_check_page
}

xmj_run_dependency_status_page() {
  xmj_dependency_reset_state
  xmj_dependency_collect_context
  xmj_render_dependency_status_page
}

xmj_run_dependency_install_page() {
  local input=''
  local detail_text=''

  xmj_dependency_reset_state
  xmj_dependency_collect_context

  while true; do
    xmj_render_dependency_install_confirm_page
    xmj_dependency_prompt_confirm_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        break
        ;;
      0)
        return 0
        ;;
      *)
        xmj_dependency_set_notice 'warn' '这里只支持输入 y / 0。'
        ;;
    esac
  done

  xmj_dependency_clear_notice
  xmj_render_dependency_progress 'install' 'prepare' 'running' '准备中' '猫猫正在整理这次依赖安装的步骤。'

  if ! xmj_dependency_prepare_log_file 'dependency-install'; then
    xmj_render_dependency_result 'install' 'failure' 'prepare' '无法创建依赖安装日志' "${XMJ_DEP_LAST_ERROR:-请检查日志目录权限。}"
    return 0
  fi

  xmj_dependency_log_line '开始执行 11 安装依赖。'

  xmj_render_dependency_progress 'install' 'env' 'running' '扫描环境' '正在确认当前仓库与依赖工具状态。'
  xmj_dependency_collect_context

  xmj_render_dependency_progress 'install' 'packages' 'running' '补齐系统依赖' '正在检查 git、node、npm 与压缩工具。'
  if ! xmj_dependency_install_termux_packages; then
    xmj_render_dependency_result 'install' 'failure' 'packages' '系统依赖没有顺利补齐' "${XMJ_DEP_LAST_ERROR:-请温和查看日志。}"
    return 0
  fi

  xmj_dependency_collect_context

  xmj_render_dependency_progress 'install' 'deps' 'running' '整理项目依赖' '如果目录里有 package.json，这里会执行 npm install。'
  if ! xmj_dependency_sync_project_dependencies; then
    xmj_render_dependency_result 'install' 'failure' 'deps' '项目依赖整理失败' "${XMJ_DEP_LAST_ERROR:-请温和查看日志。}"
    return 0
  fi

  xmj_dependency_collect_context
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_PACKAGE_INSTALL_NOTE:-}")"
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_PROJECT_DEP_NOTE:-}")"

  if [ "${XMJ_DEP_CHECK_LEVEL:-info}" = 'failure' ]; then
    detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_CHECK_DETAIL:-}")"
  fi

  xmj_render_dependency_result 'install' 'success' 'done' "$(xmj_dependency_install_result_summary)" "$detail_text"
}

xmj_run_dependency_repair_page() {
  local input=''
  local detail_text=''

  xmj_dependency_reset_state
  xmj_dependency_collect_context

  while true; do
    xmj_render_dependency_repair_confirm_page
    xmj_dependency_prompt_confirm_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      y|Y|yes|YES|Yes)
        break
        ;;
      0)
        return 0
        ;;
      *)
        xmj_dependency_set_notice 'warn' '这里只支持输入 y / 0。'
        ;;
    esac
  done

  xmj_dependency_clear_notice
  xmj_render_dependency_progress 'repair' 'prepare' 'running' '准备中' '猫猫正在整理这次异常修复的步骤。'

  if ! xmj_dependency_prepare_log_file 'dependency-repair'; then
    xmj_render_dependency_result 'repair' 'failure' 'prepare' '无法创建异常修复日志' "${XMJ_DEP_LAST_ERROR:-请检查日志目录权限。}"
    return 0
  fi

  xmj_dependency_log_line '开始执行 13 异常修复。'

  xmj_render_dependency_progress 'repair' 'env' 'running' '扫描环境' '正在确认目录、命令和仓库状态。'
  xmj_dependency_collect_context

  if ! xmj_dependency_ensure_runtime_dirs; then
    xmj_render_dependency_result 'repair' 'failure' 'env' '目录修复失败' "${XMJ_DEP_LAST_ERROR:-请检查路径权限。}"
    return 0
  fi

  xmj_render_dependency_progress 'repair' 'packages' 'running' '补齐系统依赖' '会按需补齐 git、node、npm 与压缩工具。'
  if ! xmj_dependency_install_termux_packages; then
    xmj_render_dependency_result 'repair' 'failure' 'packages' '系统依赖没有顺利补齐' "${XMJ_DEP_LAST_ERROR:-请温和查看日志。}"
    return 0
  fi

  xmj_dependency_collect_context

  xmj_render_dependency_progress 'repair' 'repo' 'running' '修复仓库状态' '如果仓库处于 detached HEAD，会尝试自动切回分支。'
  if ! xmj_dependency_repair_repo_state; then
    xmj_render_dependency_result 'repair' 'failure' 'repo' '仓库状态修复失败' "${XMJ_DEP_LAST_ERROR:-请温和查看日志。}"
    return 0
  fi

  xmj_dependency_collect_context

  xmj_render_dependency_progress 'repair' 'deps' 'running' '整理项目依赖' '如果目录里有 package.json，这里会重新执行 npm install。'
  if ! xmj_dependency_sync_project_dependencies; then
    xmj_render_dependency_result 'repair' 'failure' 'deps' '项目依赖整理失败' "${XMJ_DEP_LAST_ERROR:-请温和查看日志。}"
    return 0
  fi

  xmj_dependency_collect_context
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_DIRECTORY_NOTE:-}")"
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_PACKAGE_INSTALL_NOTE:-}")"
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_REPO_REPAIR_NOTE:-}")"
  detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_PROJECT_DEP_NOTE:-}")"

  if [ "${XMJ_DEP_CHECK_LEVEL:-info}" = 'failure' ]; then
    detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_CHECK_DETAIL:-}")"
    xmj_render_dependency_result 'repair' 'failure' 'done' "$(xmj_dependency_repair_result_summary)" "$detail_text"
    return 0
  fi

  if [ "${XMJ_DEP_CHECK_LEVEL:-info}" = 'warn' ]; then
    detail_text="$(xmj_dependency_append_detail "$detail_text" "${XMJ_DEP_CHECK_DETAIL:-}")"
  fi

  xmj_render_dependency_result 'repair' 'success' 'done' "$(xmj_dependency_repair_result_summary)" "$detail_text"
}

xmj_render_backup_archive_lines() {
  local page="${1:-1}"
  local page_size="${2:-5}"
  local total="${#XMJ_BACKUP_ARCHIVE_FILES[@]}"
  local start_index='0'
  local end_index='0'
  local i='0'
  local archive_file=''
  local archive_name=''
  local archive_scope=''

  if [ "$total" -eq 0 ]; then
    xmj_render_setting_card \
      '还没有备份档' \
      '当前备份目录里还没有 zip 备份。' \
      '可以先去 07 创建备份，再回来翻翻看。'
    return 0
  fi

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size))
  if [ "$end_index" -gt "$total" ]; then
    end_index="$total"
  fi

  printf '  %b♡ 备份档案%b\n' "$XMJ_PINK" "$XMJ_RESET"

  for ((i = start_index; i < end_index; i++)); do
    archive_file="${XMJ_BACKUP_ARCHIVE_FILES[$i]}"
    archive_name="$(basename "$archive_file")"
    archive_scope="${XMJ_BACKUP_ARCHIVE_SCOPES[$i]:-}"

    if [ -z "$archive_scope" ]; then
      archive_scope="$(xmj_backup_archive_scope_text "$archive_file")"
    fi

    printf '\n'
    printf '  %b[%02d]%b %b%s%b\n' \
      "$XMJ_PINK" $((i + 1)) "$XMJ_RESET" \
      "$XMJ_WHITE" "$archive_name" "$XMJ_RESET"
    printf '      %b时间%b：%b%s%b   %b大小%b：%b%s%b   %b范围%b：%b%s%b\n' \
      "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$(xmj_backup_archive_time_text "$archive_file")" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$(xmj_backup_archive_size_text "$archive_file")" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" "$XMJ_WHITE" "$archive_scope" "$XMJ_RESET"
  done
}

xmj_render_backup_restore_confirm_page() {
  local archive_file="${1:-}"
  local archive_name=''

  archive_name="$(basename "$archive_file")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['09']}" 'restore data' 'backup'
  printf '\n'
  xmj_render_page_intro \
    '这次会把选中的备份覆盖恢复到当前酒馆目录。' \
    '如果这是低版本兼容备份，恢复时只会放回 data。'
  printf '\n'
  xmj_render_fact_line '备份文件' "$archive_name"
  xmj_render_fact_line '备份时间' "$(xmj_backup_archive_time_text "$archive_file")"
  xmj_render_fact_line '备份大小' "$(xmj_backup_archive_size_text "$archive_file")"
  xmj_render_fact_line '备份范围' "$(xmj_backup_archive_scope_text "$archive_file")"
  xmj_render_fact_line '恢复到' "$(xmj_display_path "${XMJ_SILLYTAVERN_PATH:-}")"
  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'y' '确认恢复这个备份'
  xmj_render_action_item '0' '取消并返回上一页'
  xmj_render_action_footer '输入 y / 0。'
}

xmj_render_backup_cleanup_confirm_page() {
  local mode="${1:-single}"
  local archive_file="${2:-}"
  local keep_count=''
  local summary_text=''
  local detail_text=''

  keep_count="$(xmj_backup_cleanup_keep_count)"

  case "$mode" in
    auto)
      summary_text="会保留最新 ${keep_count} 个备份。"
      detail_text='更旧的 zip 备份会直接删掉，删完就不自动回来啦。'
      ;;
    *)
      summary_text="即将删除：$(basename "$archive_file")"
      detail_text='这里只会删掉备份档，不会碰酒馆目录本体。'
      ;;
  esac

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['10']}" 'cleanup archive' 'backup'
  printf '\n'
  xmj_render_setting_card '执行前确认' "$summary_text" "$detail_text"

  if [ "$mode" = 'single' ] && [ -n "$archive_file" ]; then
    printf '\n'
    xmj_render_fact_line '备份时间' "$(xmj_backup_archive_time_text "$archive_file")"
    xmj_render_fact_line '备份大小' "$(xmj_backup_archive_size_text "$archive_file")"
    xmj_render_fact_line '备份范围' "$(xmj_backup_archive_scope_text "$archive_file")"
  fi

  xmj_render_backup_notice
  printf '\n'
  xmj_render_action_item 'y' '确认执行这次清理'
  xmj_render_action_item '0' '取消并返回上一页'
  xmj_render_action_footer '输入 y / 0。'
}
