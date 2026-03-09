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

  backup_dir="$(xmj_maintenance_backup_dir)"
  if ! mkdir -p "$backup_dir" 2>/dev/null; then
    XMJ_MAINT_LAST_ERROR="无法创建备份目录：$backup_dir"
    return 1
  fi

  archive_name="$(xmj_maintenance_timestamp).zip"
  archive_file="$backup_dir/$archive_name"
  bundle_name="${archive_name%.zip}"

  for item in 'data' 'public/scripts/extensions/third-party' 'config.yaml'; do
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
    XMJ_MAINT_BACKUP_NOTE='没有发现 data、third-party 或 config.yaml，已跳过自动备份。'
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
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

  xmj_maintenance_log "$logger_name" "开始为${op_name}自动打包备份。"

  for item in "${items[@]}"; do
    target_path="$bundle_root/$item"
    if ! mkdir -p "$(dirname "$target_path")" 2>/dev/null; then
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='整理自动备份内容时失败。'
      return 1
    fi

    if ! cp -a "$repo_path/$item" "$target_path" 2>>"$shell_log"; then
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='整理自动备份内容时失败。'
      return 1
    fi
  done

  if ! xmj_maintenance_create_archive "$temp_root" "$bundle_name" "$archive_file" "$shell_log"; then
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='生成备份压缩包失败，可温和查看日志。'
    return 1
  fi

  rm -rf "$temp_root" 2>/dev/null || true

  XMJ_MAINT_BACKUP_FILE="$archive_file"
  XMJ_MAINT_BACKUP_NOTE="已把 ${joined_items} 打成 1 个备份压缩包。"
  if [ -n "$joined_missing" ]; then
    XMJ_MAINT_BACKUP_NOTE="${XMJ_MAINT_BACKUP_NOTE} 本次未发现 ${joined_missing}。"
  fi

  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
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

  if ! xmj_maintenance_extract_archive "$XMJ_MAINT_BACKUP_FILE" "$temp_root" "$shell_log"; then
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

  for item in 'data' 'public/scripts/extensions/third-party' 'config.yaml'; do
    source_path="$bundle_root/$item"
    if [ ! -d "$source_path" ] && [ ! -f "$source_path" ]; then
      continue
    fi

    target_path="$repo_path/$item"
    rm -rf "$target_path" 2>/dev/null || true
    if ! mkdir -p "$(dirname "$target_path")" 2>/dev/null; then
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='恢复备份内容时失败。'
      return 1
    fi

    if ! cp -a "$source_path" "$target_path" 2>>"$shell_log"; then
      rm -rf "$temp_root" 2>/dev/null || true
      XMJ_MAINT_LAST_ERROR='恢复备份内容时失败。'
      return 1
    fi

    restored_count=$((restored_count + 1))
  done

  rm -rf "$temp_root" 2>/dev/null || true

  if [ "$restored_count" -eq 0 ]; then
    XMJ_MAINT_LAST_ERROR='备份压缩包里没有可恢复的目标内容。'
    return 1
  fi

  XMJ_MAINT_BACKUP_RESTORE_NOTE='已把备份压缩包中的内容覆盖恢复到原位置。'
  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_RESTORE_NOTE"
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
      '正在把 data、third-party 和 config.yaml 打成 1 个备份压缩包。'

    if ! xmj_maintenance_create_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE" '卸载酒馆'; then
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
      '正在把 data、third-party 和 config.yaml 打成 1 个备份压缩包。'

    if ! xmj_maintenance_create_backup "$XMJ_SILLYTAVERN_PATH" 'xmj_reinstall_log_line' "$XMJ_REINSTALL_LOG_FILE" '重装酒馆'; then
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
