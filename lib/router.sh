xmj_exit_panel() {
  xmj_clear_screen
  xmj_render_header
  printf '\n'
  printf '  %b猫猫先收起面板啦。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b下次再来，我还在这里等你喵。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
  printf '\n'
}

xmj_handle_route() {
  local input="${1:-}"

  case "$input" in
    00)
      xmj_exit_panel
      return 1
      ;;
    01)
      xmj_run_tavern_launch
      return 0
      ;;
    02)
      xmj_run_tavern_update
      return 0
      ;;
    03)
      xmj_run_tavern_version_switch
      return 0
      ;;
    04)
      xmj_run_tavern_reinstall
      return 0
      ;;
    05)
      xmj_run_update_history_page
      return 0
      ;;
    19)
      xmj_run_script_setting_page 'home'
      return 0
      ;;
    20|23|24|25)
      xmj_render_menu_page "$input"
      return 0
      ;;
    21)
      xmj_run_script_setting_page 'font'
      return 0
      ;;
    22)
      xmj_run_script_setting_page 'autostart'
      return 0
      ;;
    06)
      xmj_render_menu_page "$input"
      return 0
      ;;
    07)
      xmj_run_backup_create_page
      return 0
      ;;
    08)
      xmj_run_backup_list_page
      return 0
      ;;
    09)
      xmj_run_backup_restore_page
      return 0
      ;;
    10)
      xmj_run_backup_cleanup_page
      return 0
      ;;
    11)
      xmj_run_dependency_install_page
      return 0
      ;;
    12)
      xmj_run_dependency_check_page
      return 0
      ;;
    13)
      xmj_run_dependency_repair_page
      return 0
      ;;
    14)
      xmj_run_dependency_status_page
      return 0
      ;;
    15)
      xmj_run_extend_script_entry_page
      return 0
      ;;
    16)
      xmj_run_extend_toolbox_page
      return 0
      ;;
    17)
      xmj_run_extend_followup_page
      return 0
      ;;
    18)
      xmj_run_extend_reserved_page
      return 0
      ;;
    *)
      xmj_render_invalid_input "$input"
      return 0
      ;;
  esac
}

xmj_prompt_input() {
  local panel_width
  local prompt='  菜单编号 > '

  panel_width="$(xmj_panel_width)"
  if [ "$panel_width" -lt 30 ]; then
    prompt='  编号 > '
  fi

  printf '%b%s%b' "$XMJ_PINK_SOFT" "$prompt" "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_prompt_script_setting_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  设置中心 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_setting_autostart_boot_dir() {
  printf '%s' "${HOME:-}/.termux/boot"
}

xmj_setting_autostart_script_file() {
  printf '%s/xiaomaojuan-autostart.sh' "$(xmj_setting_autostart_boot_dir)"
}

xmj_setting_autostart_status_text() {
  if [ -f "$(xmj_setting_autostart_script_file)" ]; then
    printf '%s' '已开启'
    return 0
  fi

  printf '%s' '已关闭'
}

xmj_setting_enable_autostart() {
  local home_dir="${HOME:-}"
  local boot_dir=''
  local script_file=''
  local wrapper_log=''

  if [ -z "$home_dir" ]; then
    xmj_font_set_notice 'warn' 'HOME 未设置，猫猫没法写入 Termux:Boot 目录。'
    return 1
  fi

  boot_dir="$(xmj_setting_autostart_boot_dir)"
  script_file="$(xmj_setting_autostart_script_file)"
  wrapper_log="${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}/autostart-wrapper.log"

  if ! mkdir -p "$boot_dir" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法创建自启动目录：$boot_dir"
    return 1
  fi

  if ! cat >"$script_file" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
mkdir -p "$(dirname "$wrapper_log")" 2>/dev/null || true
exec bash "${XMJ_ROOT_DIR:-.}/xiaomaojuan.sh" --autostart-launch >>"$wrapper_log" 2>&1
EOF
  then
    xmj_font_set_notice 'warn' "自启动脚本写入失败：$script_file"
    return 1
  fi

  if ! chmod +x "$script_file" 2>/dev/null; then
    xmj_font_set_notice 'warn' "自启动脚本已写入，但没法补执行权限：$script_file"
    return 1
  fi

  xmj_font_set_notice 'success' '已开启开机自启动；装好 Termux:Boot 后，重启设备会直接启动酒馆。'
  return 0
}

xmj_setting_disable_autostart() {
  local script_file=''

  script_file="$(xmj_setting_autostart_script_file)"
  if [ ! -f "$script_file" ]; then
    xmj_font_set_notice 'info' '当前本来就是关闭状态。'
    return 0
  fi

  if ! rm -f "$script_file" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法移除自启动脚本：$script_file"
    return 1
  fi

  xmj_font_set_notice 'success' '已关闭开机自启动。'
  return 0
}

xmj_setting_refresh_script_repo_state() {
  local repo_path="${XMJ_ROOT_DIR:-}"
  local repo_flag=''
  local branch_name=''
  local describe_name=''
  local exact_tag=''
  local commit_name=''
  local remote_url=''
  local upstream_ref=''
  local worktree_state=''

  XMJ_SETTING_SCRIPT_GIT_OK='0'
  XMJ_SETTING_SCRIPT_REPO_OK='0'
  XMJ_SETTING_SCRIPT_BRANCH='未识别'
  XMJ_SETTING_SCRIPT_COMMIT='未识别'
  XMJ_SETTING_SCRIPT_TAG=''
  XMJ_SETTING_SCRIPT_DESCRIBE=''
  XMJ_SETTING_SCRIPT_VERSION='未识别'
  XMJ_SETTING_SCRIPT_REMOTE='未配置'
  XMJ_SETTING_SCRIPT_UPSTREAM='未配置'
  XMJ_SETTING_SCRIPT_DIRTY='0'

  if ! command -v git >/dev/null 2>&1; then
    return 1
  fi
  XMJ_SETTING_SCRIPT_GIT_OK='1'

  if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
    return 1
  fi

  repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>/dev/null || true)"
  if [ "$repo_flag" != 'true' ]; then
    return 1
  fi
  XMJ_SETTING_SCRIPT_REPO_OK='1'

  commit_name="$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null || true)"
  branch_name="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  describe_name="$(git -C "$repo_path" describe --tags --always --dirty 2>/dev/null || true)"
  exact_tag="$(git -C "$repo_path" describe --tags --exact-match 2>/dev/null || true)"
  remote_url="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"
  upstream_ref="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  worktree_state="$(git -C "$repo_path" status --porcelain --untracked-files=no 2>/dev/null || true)"

  XMJ_SETTING_SCRIPT_COMMIT="${commit_name:-未识别}"
  XMJ_SETTING_SCRIPT_TAG="$exact_tag"
  XMJ_SETTING_SCRIPT_DESCRIBE="$describe_name"
  XMJ_SETTING_SCRIPT_REMOTE="${remote_url:-未配置}"
  XMJ_SETTING_SCRIPT_UPSTREAM="${upstream_ref:-未配置}"

  if [ -n "$branch_name" ]; then
    XMJ_SETTING_SCRIPT_BRANCH="$branch_name"
  else
    XMJ_SETTING_SCRIPT_BRANCH='detached'
  fi

  if [ -n "$exact_tag" ]; then
    XMJ_SETTING_SCRIPT_VERSION="$exact_tag"
  elif [ -n "$describe_name" ]; then
    XMJ_SETTING_SCRIPT_VERSION="$describe_name"
  elif [ -n "$commit_name" ]; then
    XMJ_SETTING_SCRIPT_VERSION="$commit_name"
  fi

  if [ -n "$worktree_state" ]; then
    XMJ_SETTING_SCRIPT_DIRTY='1'
  fi

  return 0
}

xmj_setting_script_worktree_text() {
  if [ "${XMJ_SETTING_SCRIPT_GIT_OK:-0}" != '1' ]; then
    printf '%s' '未检测到 Git'
    return 0
  fi

  if [ "${XMJ_SETTING_SCRIPT_REPO_OK:-0}" != '1' ]; then
    printf '%s' '不是 Git 仓库'
    return 0
  fi

  if [ "${XMJ_SETTING_SCRIPT_DIRTY:-0}" = '1' ]; then
    printf '%s' '有未提交改动'
    return 0
  fi

  printf '%s' '工作区干净'
}

xmj_setting_run_script_update() {
  local repo_path="${XMJ_ROOT_DIR:-}"
  local before_commit=''
  local after_commit=''
  local stamp=''
  local log_file=''

  xmj_setting_refresh_script_repo_state

  if [ "${XMJ_SETTING_SCRIPT_GIT_OK:-0}" != '1' ]; then
    xmj_font_set_notice 'warn' '当前环境没检测到 Git，脚本更新暂时跑不了。'
    return 1
  fi

  if [ "${XMJ_SETTING_SCRIPT_REPO_OK:-0}" != '1' ]; then
    xmj_font_set_notice 'warn' '脚本目录当前不是 Git 仓库，没法直接更新。'
    return 1
  fi

  if [ "${XMJ_SETTING_SCRIPT_BRANCH:-detached}" = 'detached' ]; then
    xmj_font_set_notice 'warn' '当前仓库处于 detached HEAD，先切回正常分支再更新。'
    return 1
  fi

  if [ "${XMJ_SETTING_SCRIPT_UPSTREAM:-未配置}" = '未配置' ]; then
    xmj_font_set_notice 'warn' '当前分支还没绑定上游仓库，猫猫暂时没法直接拉更新。'
    return 1
  fi

  stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stamp" ]; then
    stamp='manual'
  fi

  if ! mkdir -p "${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}" 2>/dev/null; then
    xmj_font_set_notice 'warn' '日志目录没准备好，脚本更新先停一下。'
    return 1
  fi

  log_file="${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}/script-update-${stamp}.log"
  if ! : >"$log_file" 2>/dev/null; then
    xmj_font_set_notice 'warn' "脚本更新日志创建失败：$log_file"
    return 1
  fi
  XMJ_SETTING_SCRIPT_UPDATE_LOG="$log_file"

  before_commit="${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"
  {
    printf '[%s] 开始执行脚本更新。\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf '%s' 'unknown-time')"
    printf '[info] 根目录：%s\n' "$repo_path"
    printf '[info] 当前分支：%s\n' "${XMJ_SETTING_SCRIPT_BRANCH:-detached}"
    printf '[info] 当前提交：%s\n' "$before_commit"
    git -C "$repo_path" pull --ff-only
  } >>"$log_file" 2>&1

  if [ "$?" -ne 0 ]; then
    xmj_font_set_notice 'warn' "脚本更新没跑通，细节可看：$(xmj_display_path "$log_file")"
    xmj_setting_refresh_script_repo_state
    return 1
  fi

  xmj_setting_refresh_script_repo_state
  after_commit="${XMJ_SETTING_SCRIPT_COMMIT:-未识别}"

  if [ -n "$before_commit" ] && [ "$before_commit" != "$after_commit" ]; then
    xmj_font_set_notice 'success' "脚本已更新到 ${XMJ_SETTING_SCRIPT_VERSION:-$after_commit}，建议重新打开小猫卷。"
    return 0
  fi

  xmj_font_set_notice 'info' '当前脚本已经是最新版本。'
  return 0
}

xmj_setting_log_display_limit() {
  printf '%s' '12'
}

xmj_setting_refresh_log_files() {
  local log_dir="${XMJ_LOG_DIR:-${XMJ_ROOT_DIR:-.}/logs}"
  local file=''
  local total='0'

  declare -ga XMJ_SETTING_LOG_FILES=()

  if [ -d "$log_dir" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      XMJ_SETTING_LOG_FILES+=("$file")
    done < <(ls -1t "$log_dir"/*.log 2>/dev/null || true)
  fi

  total="${#XMJ_SETTING_LOG_FILES[@]}"
  if [ "$total" -eq 0 ]; then
    XMJ_SETTING_LOG_SELECTED_INDEX='0'
    return 0
  fi

  case "${XMJ_SETTING_LOG_SELECTED_INDEX:-}" in
    ''|*[!0-9]*)
      XMJ_SETTING_LOG_SELECTED_INDEX='1'
      ;;
  esac

  if [ "${XMJ_SETTING_LOG_SELECTED_INDEX:-1}" -lt 1 ] || [ "${XMJ_SETTING_LOG_SELECTED_INDEX:-1}" -gt "$total" ]; then
    XMJ_SETTING_LOG_SELECTED_INDEX='1'
  fi
}

xmj_setting_log_display_count() {
  local total='0'
  local limit='0'

  total="${#XMJ_SETTING_LOG_FILES[@]}"
  limit="$(xmj_setting_log_display_limit)"
  if [ "$total" -lt "$limit" ]; then
    printf '%s' "$total"
    return 0
  fi

  printf '%s' "$limit"
}

xmj_setting_selected_log_file() {
  local index_text="${XMJ_SETTING_LOG_SELECTED_INDEX:-0}"
  local array_index='0'

  if [ "${#XMJ_SETTING_LOG_FILES[@]}" -eq 0 ]; then
    printf '%s' ''
    return 0
  fi

  case "$index_text" in
    ''|*[!0-9]*)
      index_text='1'
      ;;
  esac

  array_index=$((index_text - 1))
  if [ "$array_index" -lt 0 ] || [ "$array_index" -ge "${#XMJ_SETTING_LOG_FILES[@]}" ]; then
    printf '%s' ''
    return 0
  fi

  printf '%s' "${XMJ_SETTING_LOG_FILES[$array_index]}"
}

xmj_setting_log_line_count() {
  local file_path="${1:-}"
  local count='0'

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    printf '%s' '0'
    return 0
  fi

  count="$(wc -l <"$file_path" 2>/dev/null || true)"
  count="${count//[[:space:]]/}"
  case "$count" in
    ''|*[!0-9]*)
      count='0'
      ;;
  esac

  printf '%s' "$count"
}

xmj_setting_print_log_tail() {
  local file_path="${1:-}"
  local tail_size="${2:-18}"
  local total_lines='0'
  local start_line='1'
  local line=''

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    printf '  %b当前还没有可预览的日志内容。%b\n' "$XMJ_MIST" "$XMJ_RESET"
    return 0
  fi

  total_lines="$(xmj_setting_log_line_count "$file_path")"
  if [ "$tail_size" -lt 1 ]; then
    tail_size='18'
  fi

  if [ "$total_lines" -gt "$tail_size" ]; then
    start_line=$((total_lines - tail_size + 1))
  fi

  if [ "$total_lines" -eq 0 ]; then
    printf '  %b这个日志文件现在还是空的。%b\n' "$XMJ_MIST" "$XMJ_RESET"
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    printf '  %b%s%b\n' "$XMJ_WHITE" "$line" "$XMJ_RESET"
  done < <(sed -n "${start_line},${total_lines}p" "$file_path" 2>/dev/null)
}

xmj_handle_script_setting_action() {
  local view="${1:-home}"
  local input="${2:-}"
  local display_count='0'

  XMJ_SETTING_NEXT_VIEW="$view"

  case "$view" in
    home)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='exit'
          ;;
        1)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='font'
          ;;
        2)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='autostart'
          ;;
        3)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='script_update'
          ;;
        4)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='script_version'
          ;;
        5)
          xmj_font_clear_notice
          XMJ_SETTING_LOG_SELECTED_INDEX='1'
          XMJ_SETTING_NEXT_VIEW='logs'
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 4 / 5 / 0。'
          ;;
      esac
      ;;
    autostart)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_setting_enable_autostart
          ;;
        2)
          xmj_setting_disable_autostart
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 0。'
          ;;
      esac
      ;;
    font)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_install_termux_font_preset
          ;;
        2)
          xmj_restore_termux_default_font
          ;;
        3)
          xmj_manual_reload_termux_settings
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 0。'
          ;;
      esac
      ;;
    script_update)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_setting_run_script_update
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 0。'
          ;;
      esac
      ;;
    script_version)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='home'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页当前只支持输入 0 返回设置中心。'
          ;;
      esac
      ;;
    logs)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='home'
          ;;
        r|R)
          xmj_font_clear_notice
          xmj_setting_refresh_log_files
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '仅支持输入日志序号、r 或 0。'
          ;;
        *)
          xmj_setting_refresh_log_files
          display_count="$(xmj_setting_log_display_count)"
          if [ "$display_count" -eq 0 ]; then
            xmj_font_set_notice 'warn' '当前还没有可查看的日志。'
          elif [ "$input" -lt 1 ] || [ "$input" -gt "$display_count" ]; then
            xmj_font_set_notice 'warn' "这里只展示最新 1 - ${display_count} 号日志。"
          else
            xmj_font_clear_notice
            XMJ_SETTING_LOG_SELECTED_INDEX="$input"
          fi
          ;;
      esac
      ;;
    *)
      xmj_font_clear_notice
      XMJ_SETTING_NEXT_VIEW='home'
      ;;
  esac

  return 0
}

xmj_run_script_setting_page() {
  local view="${1:-home}"
  local input

  xmj_font_clear_notice

  while true; do
    xmj_render_setting_center_page "$view"
    xmj_prompt_script_setting_input
    input="${XMJ_LAST_INPUT:-}"

    xmj_handle_script_setting_action "$view" "$input"
    view="${XMJ_SETTING_NEXT_VIEW:-$view}"

    if [ "$view" = 'exit' ]; then
      return 0
    fi
  done
}

xmj_run_panel() {
  local input

  xmj_load_menu_data

  if [ "${XMJ_CONFIG_CREATED:-0}" = '1' ] \
    || [ "${#XMJ_BOOT_MESSAGES[@]}" -gt 0 ] \
    || [ "${#XMJ_BOOT_WARNINGS[@]}" -gt 0 ]; then
    xmj_render_startup_notice
  fi

  while true; do
    xmj_render_home
    XMJ_LAST_INPUT=''
    xmj_prompt_input
    input="${XMJ_LAST_INPUT:-}"

    if ! xmj_handle_route "$input"; then
      break
    fi
  done
}
