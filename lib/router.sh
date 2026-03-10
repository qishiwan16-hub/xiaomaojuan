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
    20)
      xmj_run_tavern_setting_page 'home'
      return 0
      ;;
    23|24|25)
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

xmj_prompt_tavern_setting_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  酒馆设置 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_script_password_value() {
  printf '%s' 'meoroll'
}

xmj_script_password_marker_dir() {
  if [ -n "${HOME:-}" ]; then
    printf '%s/.xiaomaojuan' "$HOME"
    return 0
  fi

  printf '%s' "${XMJ_CONFIG_DIR:-${XMJ_ROOT_DIR:-.}/config}"
}

xmj_script_password_marker_file() {
  printf '%s/install-password.ok' "$(xmj_script_password_marker_dir)"
}

xmj_script_password_first_open_required() {
  if [ -f "$(xmj_script_password_marker_file)" ]; then
    return 1
  fi

  return 0
}

xmj_script_password_mark_first_open_done() {
  local marker_dir=''
  local marker_file=''

  marker_dir="$(xmj_script_password_marker_dir)"
  marker_file="$(xmj_script_password_marker_file)"

  if ! mkdir -p "$marker_dir" 2>/dev/null; then
    return 1
  fi

  if ! : >"$marker_file" 2>/dev/null; then
    return 1
  fi

  return 0
}

xmj_prompt_script_password_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  安装密码 > ' "$XMJ_RESET"
  IFS= read -r -s XMJ_LAST_INPUT
  printf '\n'
}

xmj_require_script_password() {
  local mode="${1:-first_open}"
  local input=''
  local failed_count='0'

  xmj_font_clear_notice

  while true; do
    xmj_render_script_password_page "$mode"
    xmj_prompt_script_password_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      0)
        xmj_font_clear_notice
        return 1
        ;;
    esac

    if [ "$input" = "$(xmj_script_password_value)" ]; then
      xmj_font_clear_notice

      if [ "$mode" = 'first_open' ] && ! xmj_script_password_mark_first_open_done; then
        xmj_add_boot_warning '安装密码已经通过，但验证标记没写好，下次打开可能还会再问一次。'
      fi

      return 0
    fi

    failed_count=$((failed_count + 1))
    if [ "$failed_count" -ge 2 ]; then
      xmj_font_set_notice 'warn' '骗你的喵其实是作者名啦你不可能不知道本喵的妈咪是谁吧？'
    else
      xmj_font_set_notice 'warn' '大笨蛋铲屎官，连本喵的名字都记不住，再给你一次机会喵。'
    fi
  done
}

xmj_setting_autostart_shell_file() {
  printf '%s/.bashrc' "${HOME:-}"
}

xmj_setting_autostart_hook_begin() {
  printf '%s' '# >>> xiaomaojuan termux autostart >>>'
}

xmj_setting_autostart_hook_end() {
  printf '%s' '# <<< xiaomaojuan termux autostart <<<'
}

xmj_setting_autostart_legacy_boot_dir() {
  printf '%s' "${HOME:-}/.termux/boot"
}

xmj_setting_autostart_legacy_script_file() {
  printf '%s/xiaomaojuan-autostart.sh' "$(xmj_setting_autostart_legacy_boot_dir)"
}

xmj_setting_autostart_hook_enabled() {
  local shell_file=''
  local begin_marker=''
  local end_marker=''

  shell_file="$(xmj_setting_autostart_shell_file)"
  begin_marker="$(xmj_setting_autostart_hook_begin)"
  end_marker="$(xmj_setting_autostart_hook_end)"

  if [ ! -f "$shell_file" ]; then
    return 1
  fi

  if ! grep -Fq "$begin_marker" "$shell_file" 2>/dev/null; then
    return 1
  fi

  if ! grep -Fq "$end_marker" "$shell_file" 2>/dev/null; then
    return 1
  fi

  return 0
}

xmj_setting_autostart_status_text() {
  if xmj_setting_autostart_hook_enabled; then
    printf '%s' '已开启'
    return 0
  fi

  if [ -f "$(xmj_setting_autostart_legacy_script_file)" ]; then
    printf '%s' '旧版开机自启残留'
    return 0
  fi

  printf '%s' '已关闭'
}

xmj_setting_autostart_remove_hook() {
  local shell_file=''
  local temp_file=''
  local line=''
  local begin_marker=''
  local end_marker=''
  local skipping='0'

  shell_file="$(xmj_setting_autostart_shell_file)"
  begin_marker="$(xmj_setting_autostart_hook_begin)"
  end_marker="$(xmj_setting_autostart_hook_end)"

  if [ ! -f "$shell_file" ]; then
    return 0
  fi

  temp_file="${shell_file}.tmp.$$"
  if ! : >"$temp_file" 2>/dev/null; then
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$skipping" = '0' ] && [ "$line" = "$begin_marker" ]; then
      skipping='1'
      continue
    fi

    if [ "$skipping" = '1' ]; then
      if [ "$line" = "$end_marker" ]; then
        skipping='0'
      fi
      continue
    fi

    if ! printf '%s\n' "$line" >>"$temp_file"; then
      rm -f "$temp_file" 2>/dev/null || true
      return 1
    fi
  done <"$shell_file"

  if ! mv "$temp_file" "$shell_file" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  return 0
}

xmj_setting_autostart_remove_legacy_boot_script() {
  local legacy_script=''

  legacy_script="$(xmj_setting_autostart_legacy_script_file)"
  if [ -f "$legacy_script" ]; then
    rm -f "$legacy_script" 2>/dev/null || true
  fi
}

xmj_setting_enable_autostart() {
  local home_dir="${HOME:-}"
  local shell_file=''
  local shell_dir=''
  local script_path=''
  local escaped_script_path=''

  if [ -z "$home_dir" ]; then
    xmj_font_set_notice 'warn' 'HOME 未设置，猫猫没法写入 Termux 的启动配置。'
    return 1
  fi

  shell_file="$(xmj_setting_autostart_shell_file)"
  shell_dir="$(dirname "$shell_file")"
  script_path="${XMJ_ROOT_DIR:-.}/xiaomaojuan.sh"
  printf -v escaped_script_path '%q' "$script_path"

  if [ -n "$shell_dir" ] && [ ! -d "$shell_dir" ]; then
    if ! mkdir -p "$shell_dir" 2>/dev/null; then
      xmj_font_set_notice 'warn' "无法准备启动配置目录：$shell_dir"
      return 1
    fi
  fi

  if ! : >>"$shell_file" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法写入 Termux 启动配置：$shell_file"
    return 1
  fi

  if xmj_setting_autostart_hook_enabled; then
    xmj_setting_autostart_remove_legacy_boot_script
    xmj_font_set_notice 'info' '当前本来就是打开 Termux 自动运行小猫卷。'
    return 0
  fi

  if ! {
    printf '\n%s\n' "$(xmj_setting_autostart_hook_begin)"
    printf '%s\n' 'if [ -n "${TERMUX_VERSION:-}" ] && [[ $- == *i* ]] && [ -z "${XMJ_TERMUX_AUTOSTART_RAN:-}" ]; then'
    printf '%s\n' '  export XMJ_TERMUX_AUTOSTART_RAN=1'
    printf '%s\n' "  if [ -z \"\${XMJ_SKIP_TERMUX_AUTOSTART:-}\" ] && [ -f ${escaped_script_path} ]; then"
    printf '%s\n' "    bash ${escaped_script_path}"
    printf '%s\n' '  fi'
    printf '%s\n' 'fi'
    printf '%s\n' "$(xmj_setting_autostart_hook_end)"
  } >>"$shell_file"; then
    xmj_font_set_notice 'warn' "写入 Termux 自启动钩子失败：$shell_file"
    return 1
  fi

  xmj_setting_autostart_remove_legacy_boot_script
  xmj_font_set_notice 'success' '已开启打开 Termux 自启动；下次打开 Termux 就会自动运行小猫卷脚本。'
  return 0
}

xmj_setting_disable_autostart() {
  local shell_file=''
  local legacy_script=''

  shell_file="$(xmj_setting_autostart_shell_file)"
  legacy_script="$(xmj_setting_autostart_legacy_script_file)"

  if ! xmj_setting_autostart_hook_enabled && [ ! -f "$legacy_script" ]; then
    xmj_font_set_notice 'info' '当前本来就是关闭状态。'
    return 0
  fi

  if ! xmj_setting_autostart_remove_hook; then
    xmj_font_set_notice 'warn' "无法移除 Termux 自启动钩子：$shell_file"
    return 1
  fi

  xmj_setting_autostart_remove_legacy_boot_script
  xmj_font_set_notice 'success' '已关闭打开 Termux 自启动。'
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

  if ! xmj_require_script_password 'script_update'; then
    xmj_font_set_notice 'info' '这次脚本更新先取消啦。'
    return 1
  fi

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

xmj_tavern_setting_default_user_name() {
  printf '%s' 'default-user'
}

xmj_tavern_setting_user_name() {
  if [ -n "${XMJ_TAVERN_SETTING_STUTTER_USER:-}" ]; then
    printf '%s' "$XMJ_TAVERN_SETTING_STUTTER_USER"
    return 0
  fi

  xmj_tavern_setting_default_user_name
}

xmj_tavern_setting_config_file() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local candidate=''

  if [ -z "$repo_path" ]; then
    printf '%s' ''
    return 0
  fi

  for candidate in \
    "$repo_path/config.yaml" \
    "$repo_path/config.yml" \
    "$repo_path/data/config.yaml" \
    "$repo_path/data/config.yml"
  do
    if [ -f "$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  printf '%s' ''
}

xmj_tavern_setting_user_settings_file() {
  local user_name="${1:-$(xmj_tavern_setting_user_name)}"
  if [ -z "${XMJ_SILLYTAVERN_PATH:-}" ]; then
    printf '%s' ''
    return 0
  fi

  printf '%s/data/%s/settings.json' "${XMJ_SILLYTAVERN_PATH:-}" "$user_name"
}

xmj_tavern_setting_yaml_section_value() {
  local file_path="${1:-}"
  local section="${2:-}"
  local key="${3:-}"

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$section" ] || [ -z "$key" ]; then
    printf '%s' ''
    return 0
  fi

  awk -v section="$section" -v key="$key" '
    $0 ~ ("^" section ":[[:space:]]*($|#)") {
      in_section=1
      next
    }
    in_section && $0 ~ /^[^[:space:]#][^:]*:/ {
      in_section=0
    }
    in_section && $0 ~ ("^[[:space:]]+" key ":[[:space:]]*") {
      line=$0
      sub("^[[:space:]]*" key ":[[:space:]]*", "", line)
      sub("[[:space:]]+#.*$", "", line)
      sub(/[[:space:]]+$/, "", line)
      print line
      exit
    }
  ' "$file_path" 2>/dev/null
}

xmj_tavern_setting_yaml_top_value() {
  local file_path="${1:-}"
  local key="${2:-}"

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$key" ]; then
    printf '%s' ''
    return 0
  fi

  awk -v key="$key" '
    $0 ~ ("^" key ":[[:space:]]*") {
      line=$0
      sub("^" key ":[[:space:]]*", "", line)
      sub("[[:space:]]+#.*$", "", line)
      sub(/[[:space:]]+$/, "", line)
      print line
      exit
    }
  ' "$file_path" 2>/dev/null
}

xmj_tavern_setting_json_key_value() {
  local file_path="${1:-}"
  local key="${2:-}"

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$key" ]; then
    printf '%s' ''
    return 0
  fi

  awk -v key="$key" '
    match($0, "\"" key "\"[[:space:]]*:[[:space:]]*(true|false|null|[0-9]+|\"[^\"]*\")") {
      line=substr($0, RSTART, RLENGTH)
      sub("^\"" key "\"[[:space:]]*:[[:space:]]*", "", line)
      sub(/[[:space:]]*,?$/, "", line)
      print line
      exit
    }
  ' "$file_path" 2>/dev/null
}

xmj_tavern_setting_set_yaml_top_value() {
  local file_path="${1:-}"
  local key="${2:-}"
  local value="${3:-}"
  local temp_file=''

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$key" ]; then
    return 1
  fi

  temp_file="${file_path}.tmp.$$"
  if ! awk -v key="$key" -v value="$value" '
    BEGIN { updated=0 }
    $0 ~ ("^" key ":[[:space:]]*") {
      print key ": " value
      updated=1
      next
    }
    { print }
    END {
      if (!updated) {
        if (NR > 0) {
          print ""
        }
        print key ": " value
      }
    }
  ' "$file_path" >"$temp_file"; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  if ! mv "$temp_file" "$file_path" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  return 0
}

xmj_tavern_setting_set_yaml_section_value() {
  local file_path="${1:-}"
  local section="${2:-}"
  local key="${3:-}"
  local value="${4:-}"
  local temp_file=''

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$section" ] || [ -z "$key" ]; then
    return 1
  fi

  temp_file="${file_path}.tmp.$$"
  if ! awk -v section="$section" -v key="$key" -v value="$value" '
    function write_missing_key() {
      if (in_section && !key_written) {
        print "  " key ": " value
        key_written=1
      }
    }
    {
      line=$0

      if (in_section && line ~ /^[^[:space:]#][^:]*:/) {
        write_missing_key()
        in_section=0
      }

      if (line ~ ("^" section ":[[:space:]]*($|#)")) {
        section_found=1
        in_section=1
        key_written=0
        print line
        next
      }

      if (in_section && line ~ ("^[[:space:]]+" key ":[[:space:]]*")) {
        print "  " key ": " value
        key_written=1
        next
      }

      print line
    }
    END {
      write_missing_key()
      if (!section_found) {
        if (NR > 0) {
          print ""
        }
        print section ":"
        print "  " key ": " value
      }
    }
  ' "$file_path" >"$temp_file"; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  if ! mv "$temp_file" "$file_path" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  return 0
}

xmj_tavern_setting_set_json_bool_value() {
  local file_path="${1:-}"
  local key="${2:-}"
  local value="${3:-false}"
  local temp_file=''

  if [ -z "$file_path" ] || [ ! -f "$file_path" ] || [ -z "$key" ]; then
    return 1
  fi

  temp_file="${file_path}.tmp.$$"
  if ! awk -v key="$key" -v value="$value" '
    {
      line=$0
      if (line ~ "\"" key "\"[[:space:]]*:") {
        gsub("\"" key "\"[[:space:]]*:[[:space:]]*(true|false|null|[0-9]+|\"[^\"]*\")", "\"" key "\": " value, line)
        found=1
      }
      print line
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$file_path" >"$temp_file"; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  if ! mv "$temp_file" "$file_path" 2>/dev/null; then
    rm -f "$temp_file" 2>/dev/null || true
    return 1
  fi

  return 0
}

xmj_tavern_setting_browser_redirect_status_text() {
  local config_file=''
  local current_value=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到配置文件'
    return 0
  fi

  current_value="$(xmj_tavern_setting_yaml_section_value "$config_file" 'browserLaunch' 'enabled')"
  case "$current_value" in
    false)
      printf '%s' '当前：已关闭自动跳浏览器'
      ;;
    true)
      printf '%s' '当前：仍会自动跳浏览器'
      ;;
    *)
      printf '%s' '当前：待执行修复'
      ;;
  esac
}

xmj_tavern_setting_avatar_hd_status_text() {
  local config_file=''
  local current_value=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到配置文件'
    return 0
  fi

  current_value="$(xmj_tavern_setting_yaml_section_value "$config_file" 'thumbnails' 'enabled')"
  case "$current_value" in
    false)
      printf '%s' '当前：已关闭缩略头像'
      ;;
    true)
      printf '%s' '当前：仍在走缩略头像'
      ;;
    *)
      printf '%s' '当前：待执行修复'
      ;;
  esac
}

xmj_tavern_setting_stutter_fix_status_text() {
  local config_file=''
  local settings_file=''
  local lazy_value=''
  local auto_load_value=''
  local user_name=''

  user_name="$(xmj_tavern_setting_user_name)"
  config_file="$(xmj_tavern_setting_config_file)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  if [ -z "$config_file" ] || [ ! -f "$settings_file" ]; then
    printf '当前：用户名 %s' "$user_name"
    return 0
  fi

  lazy_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'lazyLoadCharacters')"
  auto_load_value="$(xmj_tavern_setting_json_key_value "$settings_file" 'auto_load_chat')"

  if [ "$lazy_value" = 'true' ] && [ "$auto_load_value" = 'false' ]; then
    printf '当前：%s 已套用修复' "$user_name"
    return 0
  fi

  printf '当前：用户名 %s' "$user_name"
}

xmj_tavern_setting_update_stutter_user() {
  local user_name="${1:-}"

  if [ -z "$user_name" ]; then
    xmj_font_set_notice 'warn' '用户名不能为空。'
    return 1
  fi

  case "$user_name" in
    *[[:space:]]*|*/*|*\\*)
      xmj_font_set_notice 'warn' '用户名里别放空格或斜杠喵。'
      return 1
      ;;
  esac

  XMJ_TAVERN_SETTING_STUTTER_USER="$user_name"
  xmj_font_set_notice 'success' "已把用户名改成 ${user_name}。"
  return 0
}

xmj_tavern_setting_apply_browser_redirect_fix() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_section_value "$config_file" 'browserLaunch' 'enabled' 'false'; then
    xmj_font_set_notice 'warn' "浏览器跳转修复没写进去：$(xmj_display_path "$config_file")"
    return 1
  fi

  xmj_font_set_notice 'success' "已关闭自动跳浏览器，重开酒馆后生效：$(xmj_display_path "$config_file")"
  return 0
}

xmj_tavern_setting_apply_avatar_hd_fix() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_section_value "$config_file" 'thumbnails' 'enabled' 'false'; then
    xmj_font_set_notice 'warn' "头像高清修复没写进去：$(xmj_display_path "$config_file")"
    return 1
  fi

  xmj_font_set_notice 'success' "已关闭缩略头像，重开酒馆后会直接用原图：$(xmj_display_path "$config_file")"
  return 0
}

xmj_tavern_setting_apply_stutter_fix() {
  local config_file=''
  local settings_file=''
  local user_name=''

  user_name="$(xmj_tavern_setting_user_name)"
  config_file="$(xmj_tavern_setting_config_file)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if [ ! -f "$settings_file" ]; then
    xmj_font_set_notice 'warn' "没找到这个用户的 settings.json：$(xmj_display_path "$settings_file")；没开多用户通常就是 default-user。"
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'lazyLoadCharacters' 'true'; then
    xmj_font_set_notice 'warn' "卡顿修复的第 1 步写入失败：$(xmj_display_path "$config_file")"
    return 1
  fi

  if ! xmj_tavern_setting_set_json_bool_value "$settings_file" 'auto_load_chat' 'false'; then
    xmj_font_set_notice 'warn' "卡顿修复的第 2 步写入失败：$(xmj_display_path "$settings_file")"
    return 1
  fi

  xmj_font_set_notice 'success' "已完成卡顿修复，当前用户名：${user_name}；重开酒馆后再看效果。"
  return 0
}

xmj_tavern_setting_update_backup_keep_count() {
  local keep_count="${1:-}"

  case "$keep_count" in
    ''|*[!0-9]*)
      xmj_font_set_notice 'warn' '这里只支持输入正整数。'
      return 1
      ;;
  esac

  if [ "$keep_count" -lt 1 ]; then
    xmj_font_set_notice 'warn' '备份保留数量至少要是 1。'
    return 1
  fi

  if ! xmj_config_upsert_value 'XMJ_BACKUP_KEEP_COUNT' "$keep_count"; then
    xmj_font_set_notice 'warn' "写入配置失败：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
    return 1
  fi

  xmj_font_set_notice 'success' "已把自动清理备份保留数量改成 ${keep_count}。"
  return 0
}

xmj_handle_tavern_setting_action() {
  local view="${1:-home}"
  local input="${2:-}"

  XMJ_TAVERN_SETTING_NEXT_VIEW="$view"

  case "$view" in
    home)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='exit'
          ;;
        1)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='browser_redirect'
          ;;
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='avatar_hd'
          ;;
        3)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix'
          ;;
        4)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='file_chat_limit'
          ;;
        5)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='memory_limit'
          ;;
        6)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='port_conflict'
          ;;
        7)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='chat_freeze_fix'
          ;;
        8)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='beautify_freeze_fix'
          ;;
        9)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='backup_keep_count'
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 0。'
          ;;
      esac
      ;;
    browser_redirect)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_browser_redirect_fix
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。'
          ;;
      esac
      ;;
    avatar_hd)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_avatar_hd_fix
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。'
          ;;
      esac
      ;;
    stutter_fix)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_stutter_fix
          ;;
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix_user'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 0。'
          ;;
      esac
      ;;
    stutter_fix_user)
      case "$input" in
        0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix'
          ;;
        '')
          xmj_font_set_notice 'warn' '用户名不能为空。'
          ;;
        *)
          if xmj_tavern_setting_update_stutter_user "$input"; then
            XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix'
          fi
          ;;
      esac
      ;;
    backup_keep_count)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '这里只支持输入正整数或 0。'
          ;;
        *)
          xmj_tavern_setting_update_backup_keep_count "$input"
          ;;
      esac
      ;;
    file_chat_limit|memory_limit|port_conflict|chat_freeze_fix|beautify_freeze_fix)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页当前只支持输入 0 返回酒馆设置。'
          ;;
      esac
      ;;
    *)
      xmj_font_clear_notice
      XMJ_TAVERN_SETTING_NEXT_VIEW='home'
      ;;
  esac

  return 0
}

xmj_run_tavern_setting_page() {
  local view="${1:-home}"
  local input=''

  xmj_font_clear_notice

  while true; do
    xmj_render_tavern_setting_page "$view"
    xmj_prompt_tavern_setting_input
    input="${XMJ_LAST_INPUT:-}"

    xmj_handle_tavern_setting_action "$view" "$input"
    view="${XMJ_TAVERN_SETTING_NEXT_VIEW:-$view}"

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
