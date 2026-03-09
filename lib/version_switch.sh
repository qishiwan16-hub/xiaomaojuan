xmj_version_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown-time'
  fi

  printf '%s' "$timestamp"
}

xmj_version_panel_title() {
  case "${XMJ_VERSION_TARGET_KIND:-${XMJ_VERSION_ACTIVE_MODE:-version}}" in
    branch)
      printf '%s' '切换分支'
      ;;
    *)
      printf '%s' '切换版本'
      ;;
  esac
}

xmj_version_panel_phrase() {
  case "${XMJ_VERSION_TARGET_KIND:-${XMJ_VERSION_ACTIVE_MODE:-version}}" in
    branch)
      printf '%s' 'switch branch'
      ;;
    *)
      printf '%s' 'switch version'
      ;;
  esac
}

xmj_render_version_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理切换步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_version_panel_title)" "$(xmj_version_panel_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_version_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-版本切换已完成。}"
  local detail_text="${4:-}"
  local result_title='切换完成'
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='切换失败'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_version_panel_title)" "$(xmj_version_panel_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"

  printf '\n'
  if [ -n "${XMJ_VERSION_CURRENT_LABEL:-}" ]; then
    xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL}"
  fi
  if [ -n "${XMJ_VERSION_CURRENT_BRANCH:-}" ]; then
    xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH}"
  fi
  if [ -n "${XMJ_VERSION_CURRENT_COMMIT:-}" ]; then
    xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT}"
  fi
  if [ -n "${XMJ_VERSION_TARGET_DATE:-}" ]; then
    xmj_render_fact_line '发行日期' "${XMJ_VERSION_TARGET_DATE}"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_switch_mode_page() {
  local notice_color=''

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '版本 / 分支' 'switch mode' 'update'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  printf '\n'
  xmj_render_setting_card '1 · 切换版本' '按标签切换版本，并显示发行日期。' "推荐：$(xmj_version_recommended_summary)"
  printf '\n'
  xmj_render_setting_card '2 · 切换分支' '按分支切换工作线。' "默认常用：${XMJ_VERSION_RECOMMENDED_BRANCH:-release}"

  if [ -n "${XMJ_VERSION_SELECTOR_NOTICE:-}" ]; then
    notice_color="$(xmj_version_selector_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_SELECTOR_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_render_action_item '1' '进入版本列表'
  xmj_render_action_item '2' '进入分支列表'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 0'
}

xmj_render_version_list_page() {
  local total="${#XMJ_VERSION_TAGS[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '切换版本' 'switch version' 'update'
  printf '\n'
  xmj_render_setting_card '推荐版本' "优先试 $(xmj_version_recommended_summary)。" ''
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  xmj_render_fact_line '版本总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步状态' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 可切换版本%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_version_index_marker_text "$index")"
    marker_color="$(xmj_version_index_marker_color "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_TAGS[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "${XMJ_VERSION_TAG_DATES[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一层。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_branch_list_page() {
  local total="${#XMJ_VERSION_BRANCHES[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''
  local source_text=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '切换分支' 'switch branch' 'update'
  printf '\n'
  xmj_render_setting_card '常用分支' "默认常用分支是 ${XMJ_VERSION_RECOMMENDED_BRANCH:-release}。" ''
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '分支总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步状态' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 可切换分支%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_branch_index_marker_text "$index")"
    marker_color="$(xmj_branch_index_marker_color "$index")"
    source_text="$(xmj_branch_source_text "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCHES[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "$source_text" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCH_COMMITS[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一层。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_version_reset_state() {
  XMJ_VERSION_LOG_FILE=''
  XMJ_VERSION_STAGE='prepare'
  XMJ_VERSION_SUMMARY=''
  XMJ_VERSION_DETAIL=''
  XMJ_VERSION_SELECTOR_NOTICE=''
  XMJ_VERSION_SELECTOR_NOTICE_KIND='info'
  XMJ_VERSION_ACTIVE_MODE=''
  XMJ_VERSION_HAS_LOCAL_CHANGES='0'
  XMJ_VERSION_LOCAL_NOTE=''
  XMJ_VERSION_FETCH_NOTE=''
  XMJ_VERSION_DEPENDENCY_NOTE=''
  XMJ_VERSION_BACKUP_FILE=''
  XMJ_VERSION_BACKUP_NOTE=''
  XMJ_VERSION_RECOVER_NOTE=''
  XMJ_VERSION_STASH_CREATED='0'
  XMJ_VERSION_STASH_REF=''
  XMJ_VERSION_STASH_LABEL=''
  XMJ_VERSION_RESTORE_NOTE=''
  XMJ_VERSION_BEFORE_VERSION=''
  XMJ_VERSION_BEFORE_COMMIT=''
  XMJ_VERSION_CURRENT_LABEL=''
  XMJ_VERSION_CURRENT_VERSION=''
  XMJ_VERSION_CURRENT_TAG=''
  XMJ_VERSION_CURRENT_BRANCH=''
  XMJ_VERSION_CURRENT_COMMIT=''
  XMJ_VERSION_CURRENT_DESCRIBE=''
  XMJ_VERSION_TARGET_TAG=''
  XMJ_VERSION_TARGET_BRANCH=''
  XMJ_VERSION_TARGET_KIND=''
  XMJ_VERSION_TARGET_DATE=''
  XMJ_VERSION_TARGET_COMMIT=''
  XMJ_VERSION_INPUT_NOTICE=''
  XMJ_VERSION_INPUT_NOTICE_KIND='info'
  XMJ_VERSION_PAGE='1'
  XMJ_VERSION_PAGE_SIZE='12'
  XMJ_VERSION_TOTAL_PAGES='1'
  XMJ_VERSION_RECOMMENDED_PRIMARY_TAG=''
  XMJ_VERSION_RECOMMENDED_SECONDARY_TAG=''
  XMJ_VERSION_RECOMMENDED_BRANCH='release'

  declare -ga XMJ_VERSION_TAGS=()
  declare -ga XMJ_VERSION_TAG_DATES=()
  declare -ga XMJ_VERSION_TAG_COMMITS=()
  declare -ga XMJ_VERSION_BRANCHES=()
  declare -ga XMJ_VERSION_BRANCH_SOURCES=()
  declare -ga XMJ_VERSION_BRANCH_COMMITS=()
}

xmj_version_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_VERSION_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_version_timestamp)" "$line" >>"$XMJ_VERSION_LOG_FILE"
}

xmj_version_prepare_log_file() {
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

  XMJ_VERSION_LOG_FILE="$XMJ_LOG_DIR/version-switch-$stamp.log"
  if ! : >"$XMJ_VERSION_LOG_FILE" 2>/dev/null; then
    return 1
  fi

  xmj_version_log_line '小猫卷版本切换日志已创建。'
  xmj_version_log_line "目标目录：${XMJ_SILLYTAVERN_PATH:-未设置}"
  return 0
}

xmj_version_fail() {
  local stage="${1:-env}"
  local summary="${2:-切换版本失败}"
  local detail="${3:-请温和查看日志。}"

  XMJ_VERSION_STAGE="$stage"
  XMJ_VERSION_SUMMARY="$summary"
  XMJ_VERSION_DETAIL="$detail"

  xmj_version_log_line "失败阶段：$stage"
  xmj_version_log_line "失败摘要：$summary"
  xmj_version_log_line "失败说明：$detail"
  return 1
}

xmj_version_append_detail() {
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

xmj_version_clear_notice() {
  XMJ_VERSION_INPUT_NOTICE=''
  XMJ_VERSION_INPUT_NOTICE_KIND='info'
}

xmj_version_set_notice() {
  local kind="${1:-info}"
  local message="${2:-}"

  XMJ_VERSION_INPUT_NOTICE_KIND="$kind"
  XMJ_VERSION_INPUT_NOTICE="$message"
}

xmj_version_clear_selector_notice() {
  XMJ_VERSION_SELECTOR_NOTICE=''
  XMJ_VERSION_SELECTOR_NOTICE_KIND='info'
}

xmj_version_set_selector_notice() {
  local kind="${1:-info}"
  local message="${2:-}"

  XMJ_VERSION_SELECTOR_NOTICE_KIND="$kind"
  XMJ_VERSION_SELECTOR_NOTICE="$message"
}

xmj_version_notice_color() {
  case "${XMJ_VERSION_INPUT_NOTICE_KIND:-info}" in
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_version_selector_notice_color() {
  case "${XMJ_VERSION_SELECTOR_NOTICE_KIND:-info}" in
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_BLUE_SOFT"
      ;;
  esac
}

xmj_version_tag_matches_version() {
  local tag_name="${1:-}"
  local version_text="${2:-}"

  if [ -z "$tag_name" ] || [ -z "$version_text" ]; then
    return 1
  fi

  case "$tag_name" in
    "$version_text"|"v$version_text")
      return 0
      ;;
  esac

  [ "${tag_name#v}" = "$version_text" ]
}

xmj_version_detect_recommended_tags() {
  local index='0'
  local tag_name=''

  XMJ_VERSION_RECOMMENDED_PRIMARY_TAG=''
  XMJ_VERSION_RECOMMENDED_SECONDARY_TAG=''

  for ((index = 0; index < ${#XMJ_VERSION_TAGS[@]}; index += 1)); do
    tag_name="${XMJ_VERSION_TAGS[$index]}"

    if [ -z "$XMJ_VERSION_RECOMMENDED_PRIMARY_TAG" ] \
      && xmj_version_tag_matches_version "$tag_name" '1.13.4'; then
      XMJ_VERSION_RECOMMENDED_PRIMARY_TAG="$tag_name"
    fi

    if [ -z "$XMJ_VERSION_RECOMMENDED_SECONDARY_TAG" ] \
      && xmj_version_tag_matches_version "$tag_name" '1.14.0'; then
      XMJ_VERSION_RECOMMENDED_SECONDARY_TAG="$tag_name"
    fi
  done
}

xmj_version_recommended_summary() {
  local primary='1.13.4'
  local secondary='1.14.0'

  if [ -n "${XMJ_VERSION_RECOMMENDED_PRIMARY_TAG:-}" ]; then
    primary="$XMJ_VERSION_RECOMMENDED_PRIMARY_TAG"
  fi

  if [ -n "${XMJ_VERSION_RECOMMENDED_SECONDARY_TAG:-}" ]; then
    secondary="$XMJ_VERSION_RECOMMENDED_SECONDARY_TAG"
  fi

  printf '%s 或 %s' "$primary" "$secondary"
}

xmj_version_update_current_state() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local exact_tag=''
  local branch_name=''
  local describe_name=''

  XMJ_VERSION_CURRENT_TAG=''
  XMJ_VERSION_CURRENT_BRANCH=''
  XMJ_VERSION_CURRENT_VERSION='未知'
  XMJ_VERSION_CURRENT_DESCRIBE=''
  XMJ_VERSION_CURRENT_LABEL='未知状态'
  XMJ_VERSION_CURRENT_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  branch_name="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  describe_name="$(git -C "$repo_path" describe --tags --always --dirty 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  exact_tag="$(git -C "$repo_path" describe --tags --exact-match 2>>"$XMJ_VERSION_LOG_FILE" || true)"

  if [ -n "$exact_tag" ]; then
    XMJ_VERSION_CURRENT_TAG="$exact_tag"
    XMJ_VERSION_CURRENT_VERSION="$exact_tag"
  elif [ -n "$describe_name" ]; then
    XMJ_VERSION_CURRENT_VERSION="$describe_name"
  elif [ -n "${XMJ_VERSION_CURRENT_COMMIT:-}" ]; then
    XMJ_VERSION_CURRENT_VERSION="${XMJ_VERSION_CURRENT_COMMIT}"
  fi

  XMJ_VERSION_CURRENT_DESCRIBE="${XMJ_VERSION_CURRENT_VERSION}"

  if [ -n "$branch_name" ]; then
    XMJ_VERSION_CURRENT_BRANCH="$branch_name"
    XMJ_VERSION_CURRENT_LABEL="分支：$branch_name"
    return 0
  fi

  if [ -n "$exact_tag" ]; then
    XMJ_VERSION_CURRENT_LABEL="$exact_tag"
    return 0
  fi

  if [ -n "${XMJ_VERSION_CURRENT_COMMIT:-}" ]; then
    XMJ_VERSION_CURRENT_LABEL="detached@${XMJ_VERSION_CURRENT_COMMIT}"
  fi

  return 0
}

xmj_version_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ -z "$repo_path" ]; then
    xmj_version_fail 'env' '未设置酒馆路径' '请先在配置里填写 SillyTavern 目录。'
    return 1
  fi

  if [ ! -d "$repo_path" ]; then
    xmj_version_fail 'env' '未找到酒馆目录' '请先确认配置里的 SillyTavern 目录是否正确。'
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    xmj_version_fail 'env' '未检测到 Git' '请先在 Termux 中安装 git 后再试。'
    return 1
  fi

  xmj_version_log_line '环境检查通过。'
  xmj_version_log_line "Git 版本：$(git --version 2>/dev/null || printf '%s' 'unknown')"
  return 0
}

xmj_version_check_repository() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local repo_flag=''
  local worktree_state=''

  repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  if [ "$repo_flag" != 'true' ]; then
    xmj_version_fail 'env' '目标目录不是 Git 仓库' '请确认这里是通过 Git clone 安装的 SillyTavern 目录。'
    return 1
  fi

  worktree_state="$(git -C "$repo_path" status --porcelain 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  if [ -n "$worktree_state" ]; then
    XMJ_VERSION_HAS_LOCAL_CHANGES='1'
    XMJ_VERSION_LOCAL_NOTE='检测到本地改动，切换时会先自动收好，完成后再尽量放回。'
    xmj_version_log_line '检测到本地改动，切换前会先自动 stash。'
    printf '%s\n' "$worktree_state" >>"$XMJ_VERSION_LOG_FILE"
  else
    XMJ_VERSION_HAS_LOCAL_CHANGES='0'
    XMJ_VERSION_LOCAL_NOTE='工作区干净，无需整理本地改动。'
    xmj_version_log_line "$XMJ_VERSION_LOCAL_NOTE"
  fi

  xmj_version_update_current_state
  XMJ_VERSION_BEFORE_VERSION="$XMJ_VERSION_CURRENT_VERSION"
  XMJ_VERSION_BEFORE_COMMIT="$XMJ_VERSION_CURRENT_COMMIT"
  xmj_version_log_line "当前版本：${XMJ_VERSION_CURRENT_LABEL:-unknown}"
  xmj_version_log_line "当前提交：${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  return 0
}

xmj_version_prepare_local_changes() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local stash_before=''
  local stash_after=''
  local stash_stamp=''

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" != '1' ]; then
    XMJ_VERSION_LOCAL_NOTE='本地改动无需整理。'
    xmj_version_log_line "$XMJ_VERSION_LOCAL_NOTE"
    return 0
  fi

  stash_before="$(git -C "$repo_path" rev-parse --verify -q refs/stash 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  stash_stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stash_stamp" ]; then
    stash_stamp='manual'
  fi

  XMJ_VERSION_STASH_LABEL="xmj-auto-version-switch-$stash_stamp"
  xmj_version_log_line "开始整理本地改动：${XMJ_VERSION_STASH_LABEL}"

  if ! git -C "$repo_path" stash push --include-untracked -m "$XMJ_VERSION_STASH_LABEL" >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    xmj_version_fail 'switch' '整理本地改动失败' '检测到本地改动，但没有成功临时收好，可温和查看日志。'
    return 1
  fi

  stash_after="$(git -C "$repo_path" rev-parse --verify -q refs/stash 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  if [ -z "$stash_after" ] || [ "$stash_after" = "$stash_before" ]; then
    xmj_version_fail 'switch' '整理本地改动失败' '检测到本地改动，但没有成功生成临时保存记录。'
    return 1
  fi

  XMJ_VERSION_STASH_CREATED='1'
  XMJ_VERSION_STASH_REF='stash@{0}'
  XMJ_VERSION_LOCAL_NOTE='本地改动已临时收好。'
  xmj_version_log_line "$XMJ_VERSION_LOCAL_NOTE"
  return 0
}

xmj_version_restore_local_changes() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ "${XMJ_VERSION_STASH_CREATED:-0}" != '1' ]; then
    XMJ_VERSION_RESTORE_NOTE='无需放回本地改动。'
    xmj_version_log_line "$XMJ_VERSION_RESTORE_NOTE"
    return 0
  fi

  xmj_version_log_line "开始放回本地改动：${XMJ_VERSION_STASH_REF}"
  if git -C "$repo_path" stash pop --index "$XMJ_VERSION_STASH_REF" >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    XMJ_VERSION_STASH_CREATED='0'
    XMJ_VERSION_STASH_REF=''
    XMJ_VERSION_RESTORE_NOTE='本地改动已自动放回。'
    xmj_version_log_line "$XMJ_VERSION_RESTORE_NOTE"
    return 0
  fi

  if [ -n "${XMJ_VERSION_STASH_LABEL:-}" ]; then
    XMJ_VERSION_RESTORE_NOTE="本地改动未自动放回，原始内容仍保存在 Git stash：${XMJ_VERSION_STASH_LABEL}。"
  else
    XMJ_VERSION_RESTORE_NOTE='本地改动未自动放回，原始内容仍保存在 Git stash 里。'
  fi
  xmj_version_log_line "$XMJ_VERSION_RESTORE_NOTE"
  return 1
}

xmj_version_run_backup() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if ! xmj_maintenance_create_backup "$repo_path" 'xmj_version_log_line' "$XMJ_VERSION_LOG_FILE" '版本切换'; then
    xmj_version_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成 zip 备份。}"
    return 1
  fi

  XMJ_VERSION_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
  XMJ_VERSION_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
  return 0
}

xmj_version_run_recover() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if ! xmj_maintenance_restore_backup "$repo_path" 'xmj_version_log_line' "$XMJ_VERSION_LOG_FILE"; then
    xmj_version_fail 'recover' '恢复备份失败' "${XMJ_MAINT_LAST_ERROR:-备份压缩包没有顺利恢复。}"
    return 1
  fi

  XMJ_VERSION_RECOVER_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  return 0
}

xmj_version_fetch_tags() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  XMJ_VERSION_FETCH_NOTE='已同步远程标签。'

  if ! git -C "$repo_path" remote get-url origin >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    XMJ_VERSION_FETCH_NOTE='未发现 origin，先展示当前仓库已有版本。'
    xmj_version_log_line "$XMJ_VERSION_FETCH_NOTE"
    return 0
  fi

  if git -C "$repo_path" fetch --tags --force origin >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    xmj_version_log_line '远程标签同步完成。'
    return 0
  fi

  XMJ_VERSION_FETCH_NOTE='远程标签同步未完成，先展示本地已知版本。'
  xmj_version_log_line "$XMJ_VERSION_FETCH_NOTE"
  return 0
}

xmj_version_load_tags() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local tag_name=''
  local tag_date=''
  local tag_commit=''

  declare -ga XMJ_VERSION_TAGS=()
  declare -ga XMJ_VERSION_TAG_DATES=()
  declare -ga XMJ_VERSION_TAG_COMMITS=()

  while IFS='|' read -r tag_name tag_date tag_commit; do
    if [ -z "$tag_name" ]; then
      continue
    fi

    XMJ_VERSION_TAGS+=("$tag_name")
    XMJ_VERSION_TAG_DATES+=("${tag_date:-unknown-date}")
    XMJ_VERSION_TAG_COMMITS+=("${tag_commit:-unknown}")
  done < <(
    git -C "$repo_path" for-each-ref \
      --sort=-creatordate \
      --format='%(refname:strip=2)|%(creatordate:short)|%(objectname:short)' \
      refs/tags 2>>"$XMJ_VERSION_LOG_FILE"
  )

  if [ "${#XMJ_VERSION_TAGS[@]}" -eq 0 ]; then
    xmj_version_fail 'fetch' '未找到可切换版本' '当前仓库没有可用的 Git 标签。'
    return 1
  fi

  XMJ_VERSION_TOTAL_PAGES=$(((${#XMJ_VERSION_TAGS[@]} + XMJ_VERSION_PAGE_SIZE - 1) / XMJ_VERSION_PAGE_SIZE))
  if [ "$XMJ_VERSION_TOTAL_PAGES" -lt 1 ]; then
    XMJ_VERSION_TOTAL_PAGES='1'
  fi

  xmj_version_detect_recommended_tags
  xmj_version_log_line "已整理版本数量：${#XMJ_VERSION_TAGS[@]}"
  return 0
}

xmj_version_ensure_page_range() {
  if [ "${XMJ_VERSION_PAGE:-1}" -lt 1 ]; then
    XMJ_VERSION_PAGE='1'
  fi

  if [ "${XMJ_VERSION_PAGE:-1}" -gt "${XMJ_VERSION_TOTAL_PAGES:-1}" ]; then
    XMJ_VERSION_PAGE="${XMJ_VERSION_TOTAL_PAGES:-1}"
  fi
}

xmj_version_refresh_catalog() {
  xmj_render_version_progress \
    'fetch' \
    'running' \
    '整理版本列表' \
    '猫猫正在同步标签并整理版本清单喵~'

  xmj_version_fetch_tags
  if ! xmj_version_load_tags; then
    return 1
  fi

  xmj_version_ensure_page_range
  return 0
}

xmj_branch_refresh_catalog() {
  xmj_render_version_progress \
    'fetch' \
    'running' \
    '整理分支列表' \
    '猫猫正在同步远程分支并整理切换清单喵~'

  xmj_branch_fetch_refs
  if ! xmj_branch_load_refs; then
    return 1
  fi

  xmj_version_ensure_page_range
  return 0
}

xmj_branch_fetch_refs() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  XMJ_VERSION_FETCH_NOTE='已同步远程分支。'

  if ! git -C "$repo_path" remote get-url origin >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    XMJ_VERSION_FETCH_NOTE='未发现 origin，先展示当前仓库已有本地分支。'
    xmj_version_log_line "$XMJ_VERSION_FETCH_NOTE"
    return 0
  fi

  if git -C "$repo_path" fetch origin --prune >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    xmj_version_log_line '远程分支同步完成。'
    return 0
  fi

  XMJ_VERSION_FETCH_NOTE='远程分支同步未完成，先展示本地已知分支。'
  xmj_version_log_line "$XMJ_VERSION_FETCH_NOTE"
  return 0
}

xmj_branch_load_refs() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local branch_name=''
  local branch_commit=''
  local branch_source=''

  declare -ga XMJ_VERSION_BRANCHES=()
  declare -ga XMJ_VERSION_BRANCH_SOURCES=()
  declare -ga XMJ_VERSION_BRANCH_COMMITS=()
  declare -A xmj_seen_branches=()

  while IFS='|' read -r branch_name branch_commit branch_source; do
    if [ -z "$branch_name" ] || [ "$branch_name" = 'HEAD' ]; then
      continue
    fi

    if [ -n "${xmj_seen_branches[$branch_name]+x}" ]; then
      continue
    fi

    xmj_seen_branches[$branch_name]='1'
    XMJ_VERSION_BRANCHES+=("$branch_name")
    XMJ_VERSION_BRANCH_COMMITS+=("${branch_commit:-unknown}")
    XMJ_VERSION_BRANCH_SOURCES+=("${branch_source:-origin}")
  done < <(
    {
      git -C "$repo_path" for-each-ref \
        --sort=refname \
        --format='%(refname:strip=3)|%(objectname:short)|origin' \
        refs/remotes/origin
      git -C "$repo_path" for-each-ref \
        --sort=refname \
        --format='%(refname:strip=2)|%(objectname:short)|local' \
        refs/heads
    } 2>>"$XMJ_VERSION_LOG_FILE"
  )

  if [ "${#XMJ_VERSION_BRANCHES[@]}" -eq 0 ]; then
    xmj_version_fail 'fetch' '未找到可切换分支' '当前仓库没有可用的 Git 分支。'
    return 1
  fi

  XMJ_VERSION_TOTAL_PAGES=$(((${#XMJ_VERSION_BRANCHES[@]} + XMJ_VERSION_PAGE_SIZE - 1) / XMJ_VERSION_PAGE_SIZE))
  if [ "$XMJ_VERSION_TOTAL_PAGES" -lt 1 ]; then
    XMJ_VERSION_TOTAL_PAGES='1'
  fi

  xmj_version_log_line "已整理分支数量：${#XMJ_VERSION_BRANCHES[@]}"
  return 0
}

xmj_version_index_marker_text() {
  local index="${1:-0}"
  local tag_name=''

  if [ "$index" -lt 0 ] || [ "$index" -ge "${#XMJ_VERSION_TAGS[@]}" ]; then
    printf '%s' ''
    return 0
  fi

  tag_name="${XMJ_VERSION_TAGS[$index]}"

  if [ -n "${XMJ_VERSION_CURRENT_TAG:-}" ] && [ "$tag_name" = "$XMJ_VERSION_CURRENT_TAG" ]; then
    if [ "$tag_name" = "${XMJ_VERSION_RECOMMENDED_PRIMARY_TAG:-}" ] \
      || [ "$tag_name" = "${XMJ_VERSION_RECOMMENDED_SECONDARY_TAG:-}" ]; then
      printf '%s' '当前 / 推荐'
    else
      printf '%s' '当前'
    fi
    return 0
  fi

  if [ "$tag_name" = "${XMJ_VERSION_RECOMMENDED_PRIMARY_TAG:-}" ] \
    || [ "$tag_name" = "${XMJ_VERSION_RECOMMENDED_SECONDARY_TAG:-}" ]; then
    printf '%s' '推荐'
    return 0
  fi

  printf '%s' ''
}

xmj_version_index_marker_color() {
  local index="${1:-0}"
  local marker_text=''

  marker_text="$(xmj_version_index_marker_text "$index")"
  case "$marker_text" in
    当前* )
      printf '%s' "$XMJ_CREAM"
      ;;
    推荐)
      printf '%s' "$XMJ_PINK"
      ;;
    *)
      printf '%s' "$XMJ_MIST"
      ;;
  esac
}

xmj_branch_index_marker_text() {
  local index="${1:-0}"
  local branch_name=''

  if [ "$index" -lt 0 ] || [ "$index" -ge "${#XMJ_VERSION_BRANCHES[@]}" ]; then
    printf '%s' ''
    return 0
  fi

  branch_name="${XMJ_VERSION_BRANCHES[$index]}"

  if [ -n "${XMJ_VERSION_CURRENT_BRANCH:-}" ] && [ "$branch_name" = "$XMJ_VERSION_CURRENT_BRANCH" ]; then
    if [ "$branch_name" = "${XMJ_VERSION_RECOMMENDED_BRANCH:-release}" ]; then
      printf '%s' '当前 / 默认'
    else
      printf '%s' '当前'
    fi
    return 0
  fi

  if [ "$branch_name" = "${XMJ_VERSION_RECOMMENDED_BRANCH:-release}" ]; then
    printf '%s' '默认'
    return 0
  fi

  printf '%s' ''
}

xmj_branch_index_marker_color() {
  local index="${1:-0}"
  local marker_text=''

  marker_text="$(xmj_branch_index_marker_text "$index")"
  case "$marker_text" in
    当前* )
      printf '%s' "$XMJ_CREAM"
      ;;
    默认)
      printf '%s' "$XMJ_PINK"
      ;;
    *)
      printf '%s' "$XMJ_MIST"
      ;;
  esac
}

xmj_branch_source_text() {
  local index="${1:-0}"

  if [ "$index" -lt 0 ] || [ "$index" -ge "${#XMJ_VERSION_BRANCH_SOURCES[@]}" ]; then
    printf '%s' 'unknown'
    return 0
  fi

  case "${XMJ_VERSION_BRANCH_SOURCES[$index]:-origin}" in
    local)
      printf '%s' '本地'
      ;;
    *)
      printf '%s' 'origin'
      ;;
  esac
}

xmj_version_stage_order() {
  case "${1:-}" in
    prepare) printf '%s' '1' ;;
    env) printf '%s' '2' ;;
    fetch) printf '%s' '3' ;;
    backup) printf '%s' '4' ;;
    local) printf '%s' '5' ;;
    switch) printf '%s' '6' ;;
    deps) printf '%s' '7' ;;
    recover) printf '%s' '8' ;;
    restore) printf '%s' '9' ;;
    done) printf '%s' '10' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_version_stage_label() {
  case "${1:-}" in
    prepare) printf '%s' '准备中' ;;
    env) printf '%s' '检查环境' ;;
    fetch) printf '%s' '整理版本列表' ;;
    backup) printf '%s' '自动备份' ;;
    local) printf '%s' '整理本地改动' ;;
    switch) printf '%s' '切换版本' ;;
    deps) printf '%s' '同步依赖' ;;
    recover) printf '%s' '恢复备份' ;;
    restore) printf '%s' '放回本地改动' ;;
    done) printf '%s' '完成' ;;
    *) printf '%s' '切换版本' ;;
  esac
}

xmj_render_version_stage_line() {
  local stage="${1:-prepare}"
  local current_stage="${2:-prepare}"
  local stage_mode="${3:-running}"
  local stage_order='0'
  local current_order='0'
  local marker='·'
  local state_text='等待中'
  local color="$XMJ_MIST"

  stage_order="$(xmj_version_stage_order "$stage")"
  current_order="$(xmj_version_stage_order "$current_stage")"

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
    "$XMJ_WHITE" "$(xmj_version_stage_label "$stage")" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$color" "$state_text" "$XMJ_RESET"
}

xmj_render_version_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理版本切换步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_intro \
    '切换版本进行中，详细 Git / npm 输出会悄悄写进日志本。' \
    '前台只保留简洁阶段提示，避免直接刷满。'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"

  if [ -n "${XMJ_VERSION_LOG_FILE:-}" ]; then
    printf '\n'
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_VERSION_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_version_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-版本切换已完成。}"
  local detail_text="${4:-}"
  local result_title='切换完成'
  local result_intro='猫猫已经把版本切换整理好了。'
  local result_hint=''
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='切换失败'
    result_intro='这次版本切换没有顺利完成。'
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
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"

  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"

  if [ -n "${XMJ_VERSION_BACKUP_FILE:-}" ]; then
    xmj_render_fact_line '自动备份' "$(xmj_display_path "$XMJ_VERSION_BACKUP_FILE")"
  fi

  if [ -n "${XMJ_VERSION_TARGET_DATE:-}" ]; then
    xmj_render_fact_line '发行日期' "${XMJ_VERSION_TARGET_DATE}"
  fi

  if [ -n "${XMJ_VERSION_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_VERSION_LOG_FILE")"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_switch_mode_page() {
  local notice_color=''

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_identity '03' "${XMJ_MENU_LABEL['03']}"
  printf '\n'
  xmj_render_page_intro \
    '酒馆的版本和分支是两套东西，这里先选你要切哪一种。' \
    '分支最常用的是 release，版本则会按标签和发行日期来列出。'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  printf '\n'
  xmj_render_setting_card '1 · 更换版本' '按标签切换版本，并显示发行日期。' "推荐：$(xmj_version_recommended_summary)"
  printf '\n'
  xmj_render_setting_card '2 · 更换分支' '按分支切换工作线。' "最常用默认：${XMJ_VERSION_RECOMMENDED_BRANCH:-release}"

  if [ -n "${XMJ_VERSION_SELECTOR_NOTICE:-}" ]; then
    notice_color="$(xmj_version_selector_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_SELECTOR_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_render_action_item '1' '进入版本列表'
  xmj_render_action_item '2' '进入分支列表'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 0。'
}

xmj_render_version_list_page() {
  local total="${#XMJ_VERSION_TAGS[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_identity '03' "${XMJ_MENU_LABEL['03']}"
  printf '\n'
  xmj_render_page_intro \
    '这里会列出当前仓库已知的全部版本标签和发行日期。' \
    '输入对应序号即可切换，n / p 翻页，r 刷新版本列表，0 返回上一级。'
  printf '\n'
  xmj_render_setting_card \
    '推荐版本' \
    "优先试 $(xmj_version_recommended_summary)。" \
    '如果列表里存在对应标签，会在后面标出推荐。'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  xmj_render_fact_line '版本总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步说明' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  if [ -n "${XMJ_VERSION_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_VERSION_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  printf '  %b♡ 可切换版本%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_version_index_marker_text "$index")"
    marker_color="$(xmj_version_index_marker_color "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_TAGS[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "${XMJ_VERSION_TAG_DATES[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一级。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_render_branch_list_page() {
  local total="${#XMJ_VERSION_BRANCHES[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''
  local source_text=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title 'update'
  printf '\n'
  xmj_render_page_identity '03' "${XMJ_MENU_LABEL['03']}"
  printf '\n'
  xmj_render_page_intro \
    '这里会列出当前仓库可切换的分支。' \
    '输入对应序号即可切换，n / p 翻页，r 刷新分支列表，0 返回上一级。'
  printf '\n'
  xmj_render_setting_card \
    '常用分支' \
    "最常用默认分支是 ${XMJ_VERSION_RECOMMENDED_BRANCH:-release}。" \
    '如果列表里存在对应分支，会在后面标出默认。'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '分支总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步说明' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  if [ -n "${XMJ_VERSION_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_VERSION_LOG_FILE")"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  printf '  %b♡ 可切换分支%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_branch_index_marker_text "$index")"
    marker_color="$(xmj_branch_index_marker_color "$index")"
    source_text="$(xmj_branch_source_text "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCHES[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "$source_text" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCH_COMMITS[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一级。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_version_prompt_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  版本序号 / n / p / r / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_branch_prompt_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  分支序号 / n / p / r / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_version_prompt_mode_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  选择 1 / 2 / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_version_target_detail() {
  local detail_text=''

  detail_text="发行日期：${XMJ_VERSION_TARGET_DATE:-unknown-date}。"
  detail_text="${detail_text} 当前会停留在标签版本上，后续若要继续跟随更新，建议再切回主分支。"

  if [ -n "${XMJ_VERSION_BACKUP_NOTE:-}" ]; then
    detail_text="$(xmj_version_append_detail "$detail_text" "$XMJ_VERSION_BACKUP_NOTE")"
  fi

  if [ -n "${XMJ_VERSION_RECOVER_NOTE:-}" ]; then
    detail_text="$(xmj_version_append_detail "$detail_text" "$XMJ_VERSION_RECOVER_NOTE")"
  fi

  case "${XMJ_VERSION_RESTORE_NOTE:-}" in
    ''|'无需放回本地改动。')
      ;;
    *)
      detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
      ;;
  esac

  printf '%s' "$detail_text"
}

xmj_branch_target_detail() {
  local detail_text=''

  detail_text="当前已切到分支 ${XMJ_VERSION_TARGET_BRANCH:-unknown}。"
  detail_text="${detail_text} 最常用默认分支仍是 ${XMJ_VERSION_RECOMMENDED_BRANCH:-release}。"

  if [ -n "${XMJ_VERSION_BACKUP_NOTE:-}" ]; then
    detail_text="$(xmj_version_append_detail "$detail_text" "$XMJ_VERSION_BACKUP_NOTE")"
  fi

  if [ -n "${XMJ_VERSION_RECOVER_NOTE:-}" ]; then
    detail_text="$(xmj_version_append_detail "$detail_text" "$XMJ_VERSION_RECOVER_NOTE")"
  fi

  case "${XMJ_VERSION_RESTORE_NOTE:-}" in
    ''|'无需放回本地改动。')
      ;;
    *)
      detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
      ;;
  esac

  printf '%s' "$detail_text"
}

xmj_version_write_history() {
  local action_kind=''
  local note_text=''

  action_kind="$(xmj_maintenance_classify_change "${XMJ_SILLYTAVERN_PATH:-}" "${XMJ_VERSION_BEFORE_COMMIT:-}" "${XMJ_VERSION_CURRENT_COMMIT:-}" "$XMJ_VERSION_LOG_FILE")"
  if [ -z "$action_kind" ]; then
    xmj_version_log_line '本次切换没有产生新的版本变化，跳过写入更新记录。'
    return 0
  fi

  if [ "${XMJ_VERSION_ACTIVE_MODE:-version}" = 'branch' ]; then
    note_text="切换分支：${XMJ_VERSION_CURRENT_BRANCH:-unknown}。提交：${XMJ_VERSION_BEFORE_COMMIT:-unknown} -> ${XMJ_VERSION_CURRENT_COMMIT:-unknown}。"
  else
    note_text="切换版本：${XMJ_VERSION_TARGET_TAG:-unknown}。提交：${XMJ_VERSION_BEFORE_COMMIT:-unknown} -> ${XMJ_VERSION_CURRENT_COMMIT:-unknown}。"
  fi

  if ! xmj_maintenance_record_history "$action_kind" "${XMJ_VERSION_CURRENT_VERSION:-未知}" "$note_text" 'xmj_version_log_line'; then
    xmj_version_log_line "更新记录写入失败：${XMJ_MAINT_LAST_ERROR:-unknown}"
  fi

  return 0
}

xmj_version_sync_dependencies() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ ! -f "$repo_path/package.json" ]; then
    XMJ_VERSION_DEPENDENCY_NOTE='未发现 package.json，已跳过依赖同步。'
    xmj_version_log_line "$XMJ_VERSION_DEPENDENCY_NOTE"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    xmj_version_fail 'deps' '未检测到 npm' '版本已切换，但当前环境无法完成依赖整理。'
    return 1
  fi

  if ! (
    cd "$repo_path" || exit 1
    npm install --no-audit --no-fund
  ) >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    xmj_version_fail 'deps' '同步依赖失败' '版本已切换，但依赖整理没有顺利完成，可温和查看日志。'
    return 1
  fi

  XMJ_VERSION_DEPENDENCY_NOTE='依赖同步已完成。'
  xmj_version_log_line "$XMJ_VERSION_DEPENDENCY_NOTE"
  return 0
}

xmj_version_checkout_target() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local target_tag="${1:-}"

  if [ -z "$target_tag" ]; then
    xmj_version_fail 'switch' '未识别到目标版本' '请重新选择要切换的版本。'
    return 1
  fi

  xmj_version_log_line "准备切换到版本：$target_tag"

  if ! git -C "$repo_path" checkout --detach "$target_tag" >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
    xmj_version_fail 'switch' '切换版本失败' 'Git 没有顺利切到目标版本，可温和查看日志。'
    return 1
  fi

  xmj_version_update_current_state
  XMJ_VERSION_TARGET_COMMIT="$XMJ_VERSION_CURRENT_COMMIT"
  xmj_version_log_line "已切换到版本：${XMJ_VERSION_CURRENT_LABEL:-$target_tag}"
  xmj_version_log_line "切换后提交：${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  return 0
}

xmj_branch_checkout_target() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local target_branch="${1:-}"

  if [ -z "$target_branch" ]; then
    xmj_version_fail 'switch' '未识别到目标分支' '请重新选择要切换的分支。'
    return 1
  fi

  xmj_version_log_line "准备切换到分支：$target_branch"

  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$target_branch"; then
    if ! git -C "$repo_path" checkout "$target_branch" >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
      xmj_version_fail 'switch' '切换分支失败' '本地分支没有顺利切换，可温和查看日志。'
      return 1
    fi
  elif git -C "$repo_path" show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
    if ! git -C "$repo_path" checkout -b "$target_branch" --track "origin/$target_branch" >>"$XMJ_VERSION_LOG_FILE" 2>&1; then
      xmj_version_fail 'switch' '切换分支失败' '远程分支没有顺利切换到本地，可温和查看日志。'
      return 1
    fi
  else
    xmj_version_fail 'switch' '未找到目标分支' '当前仓库里没有找到你选择的分支。'
    return 1
  fi

  XMJ_VERSION_TARGET_BRANCH="$target_branch"
  xmj_version_update_current_state
  XMJ_VERSION_TARGET_COMMIT="$XMJ_VERSION_CURRENT_COMMIT"
  xmj_version_log_line "已切换到分支：${XMJ_VERSION_CURRENT_BRANCH:-$target_branch}"
  xmj_version_log_line "切换后提交：${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  return 0
}

xmj_version_run_switch() {
  local selected_index="${1:-0}"
  local selected_number='0'
  local array_index='0'
  local target_tag=''
  local target_date=''
  local detail_text=''

  selected_number=$((10#$selected_index))
  array_index=$((selected_number - 1))
  if [ "$array_index" -lt 0 ] || [ "$array_index" -ge "${#XMJ_VERSION_TAGS[@]}" ]; then
    xmj_version_set_notice 'warn' '输入的序号不在当前版本列表里，请重新选择。'
    return 0
  fi

  target_tag="${XMJ_VERSION_TAGS[$array_index]}"
  target_date="${XMJ_VERSION_TAG_DATES[$array_index]}"
  XMJ_VERSION_TARGET_TAG="$target_tag"
  XMJ_VERSION_TARGET_BRANCH=''
  XMJ_VERSION_TARGET_DATE="$target_date"
  XMJ_VERSION_TARGET_KIND='version'

  if [ -n "${XMJ_VERSION_CURRENT_TAG:-}" ] && [ "$target_tag" = "$XMJ_VERSION_CURRENT_TAG" ]; then
    XMJ_VERSION_STAGE='done'
    XMJ_VERSION_SUMMARY="当前已经是 ${target_tag}"
    XMJ_VERSION_DETAIL="发行日期：${target_date}。无需重复切换。"
    xmj_render_version_result \
      'success' \
      'done' \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  XMJ_VERSION_BEFORE_VERSION="$XMJ_VERSION_CURRENT_VERSION"
  XMJ_VERSION_BEFORE_COMMIT="$XMJ_VERSION_CURRENT_COMMIT"

  xmj_render_version_progress \
    'backup' \
    'running' \
    '自动备份' \
    '正在把 data、third-party 和 config.yaml 打包成 zip 备份。'

  if ! xmj_version_run_backup; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'local' \
    'running' \
    '整理本地改动' \
    '若检测到未提交内容，会先轻轻收进临时口袋。'

  xmj_render_version_progress \
    'switch' \
    'running' \
    '切换版本' \
    "猫猫正在把酒馆切到 ${target_tag} 喵~ 如有本地改动会先自动收好。"

  if ! xmj_version_prepare_local_changes; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  if ! xmj_version_checkout_target "$target_tag"; then
    if [ -n "${XMJ_VERSION_BACKUP_FILE:-}" ]; then
      xmj_render_version_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '切换没有完成，先把自动备份的内容覆盖恢复回来。'

      if xmj_version_run_recover; then
        XMJ_VERSION_DETAIL="$(xmj_version_append_detail "$XMJ_VERSION_DETAIL" "$XMJ_VERSION_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
      if xmj_version_restore_local_changes; then
        detail_text="${XMJ_VERSION_DETAIL}"
        if [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ] && [ "${XMJ_VERSION_RESTORE_NOTE}" != '无需放回本地改动。' ]; then
          detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        fi
        XMJ_VERSION_DETAIL="$detail_text"
      elif [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ]; then
        detail_text="${XMJ_VERSION_DETAIL}"
        detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        XMJ_VERSION_DETAIL="$detail_text"
      fi
    fi

    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'deps' \
    'running' \
    '同步依赖' \
    '版本已经切过去了，正在确认依赖是否需要整理。'

  if ! xmj_version_sync_dependencies; then
    if [ -n "${XMJ_VERSION_BACKUP_FILE:-}" ]; then
      xmj_render_version_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '依赖整理没有完成，先把自动备份的内容覆盖恢复回来。'

      if xmj_version_run_recover; then
        XMJ_VERSION_DETAIL="$(xmj_version_append_detail "$XMJ_VERSION_DETAIL" "$XMJ_VERSION_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
      if xmj_version_restore_local_changes; then
        detail_text="${XMJ_VERSION_DETAIL}"
        if [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ] && [ "${XMJ_VERSION_RESTORE_NOTE}" != '无需放回本地改动。' ]; then
          detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        fi
        XMJ_VERSION_DETAIL="$detail_text"
      elif [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ]; then
        detail_text="${XMJ_VERSION_DETAIL}"
        detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        XMJ_VERSION_DETAIL="$detail_text"
      fi
    fi

    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'recover' \
    'running' \
    '恢复备份' \
    '代码与依赖已经切换完成，正在把自动备份的内容覆盖恢复回来。'

  if ! xmj_version_run_recover; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
    xmj_render_version_progress \
      'restore' \
      'running' \
      '放回本地改动' \
      '正在把刚才收好的本地改动放回原位。'

    if ! xmj_version_restore_local_changes; then
      xmj_version_log_line '版本已切换成功，但本地改动未自动放回。'
    fi
  fi

  XMJ_VERSION_STAGE='done'
  XMJ_VERSION_SUMMARY="已切换到 ${XMJ_VERSION_CURRENT_LABEL:-$target_tag}"
  XMJ_VERSION_DETAIL="$(xmj_version_target_detail)"
  xmj_version_write_history
  xmj_version_log_line "结果摘要：$XMJ_VERSION_SUMMARY"
  xmj_version_log_line "结果说明：$XMJ_VERSION_DETAIL"

  xmj_render_version_result \
    'success' \
    'done' \
    "$XMJ_VERSION_SUMMARY" \
    "$XMJ_VERSION_DETAIL"
  return 1
}

xmj_branch_run_switch() {
  local selected_index="${1:-0}"
  local selected_number='0'
  local array_index='0'
  local target_branch=''
  local detail_text=''

  selected_number=$((10#$selected_index))
  array_index=$((selected_number - 1))
  if [ "$array_index" -lt 0 ] || [ "$array_index" -ge "${#XMJ_VERSION_BRANCHES[@]}" ]; then
    xmj_version_set_notice 'warn' '输入的序号不在当前分支列表里，请重新选择。'
    return 0
  fi

  target_branch="${XMJ_VERSION_BRANCHES[$array_index]}"
  XMJ_VERSION_TARGET_TAG=''
  XMJ_VERSION_TARGET_BRANCH="$target_branch"
  XMJ_VERSION_TARGET_DATE=''
  XMJ_VERSION_TARGET_KIND='branch'

  if [ -n "${XMJ_VERSION_CURRENT_BRANCH:-}" ] && [ "$target_branch" = "$XMJ_VERSION_CURRENT_BRANCH" ]; then
    XMJ_VERSION_STAGE='done'
    XMJ_VERSION_SUMMARY="当前已经在分支 ${target_branch}"
    XMJ_VERSION_DETAIL='无需重复切换。'
    xmj_render_version_result \
      'success' \
      'done' \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  XMJ_VERSION_BEFORE_VERSION="$XMJ_VERSION_CURRENT_VERSION"
  XMJ_VERSION_BEFORE_COMMIT="$XMJ_VERSION_CURRENT_COMMIT"

  xmj_render_version_progress \
    'backup' \
    'running' \
    '自动备份' \
    '正在把 data、third-party 和 config.yaml 打包成 zip 备份。'

  if ! xmj_version_run_backup; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'local' \
    'running' \
    '整理本地改动' \
    '若检测到未提交内容，会先轻轻收进临时口袋。'

  xmj_render_version_progress \
    'switch' \
    'running' \
    '切换分支' \
    "猫猫正在把酒馆切到分支 ${target_branch} 喵~ 如有本地改动会先自动收好。"

  if ! xmj_version_prepare_local_changes; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  if ! xmj_branch_checkout_target "$target_branch"; then
    if [ -n "${XMJ_VERSION_BACKUP_FILE:-}" ]; then
      xmj_render_version_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '切换没有完成，先把自动备份的内容覆盖恢复回来。'

      if xmj_version_run_recover; then
        XMJ_VERSION_DETAIL="$(xmj_version_append_detail "$XMJ_VERSION_DETAIL" "$XMJ_VERSION_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
      if xmj_version_restore_local_changes; then
        detail_text="${XMJ_VERSION_DETAIL}"
        if [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ] && [ "${XMJ_VERSION_RESTORE_NOTE}" != '无需放回本地改动。' ]; then
          detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        fi
        XMJ_VERSION_DETAIL="$detail_text"
      elif [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ]; then
        detail_text="${XMJ_VERSION_DETAIL}"
        detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        XMJ_VERSION_DETAIL="$detail_text"
      fi
    fi

    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'deps' \
    'running' \
    '同步依赖' \
    '分支已经切过去了，正在确认依赖是否需要整理。'

  if ! xmj_version_sync_dependencies; then
    if [ -n "${XMJ_VERSION_BACKUP_FILE:-}" ]; then
      xmj_render_version_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '依赖整理没有完成，先把自动备份的内容覆盖恢复回来。'

      if xmj_version_run_recover; then
        XMJ_VERSION_DETAIL="$(xmj_version_append_detail "$XMJ_VERSION_DETAIL" "$XMJ_VERSION_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
      if xmj_version_restore_local_changes; then
        detail_text="${XMJ_VERSION_DETAIL}"
        if [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ] && [ "${XMJ_VERSION_RESTORE_NOTE}" != '无需放回本地改动。' ]; then
          detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        fi
        XMJ_VERSION_DETAIL="$detail_text"
      elif [ -n "${XMJ_VERSION_RESTORE_NOTE:-}" ]; then
        detail_text="${XMJ_VERSION_DETAIL}"
        detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
        XMJ_VERSION_DETAIL="$detail_text"
      fi
    fi

    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  xmj_render_version_progress \
    'recover' \
    'running' \
    '恢复备份' \
    '代码与依赖已经切换完成，正在把自动备份的内容覆盖恢复回来。'

  if ! xmj_version_run_recover; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
    xmj_render_version_progress \
      'restore' \
      'running' \
      '放回本地改动' \
      '正在把刚才收好的本地改动放回原位。'

    if ! xmj_version_restore_local_changes; then
      xmj_version_log_line '分支已切换成功，但本地改动未自动放回。'
    fi
  fi

  XMJ_VERSION_STAGE='done'
  XMJ_VERSION_SUMMARY="已切换到分支 ${XMJ_VERSION_CURRENT_BRANCH:-$target_branch}"
  XMJ_VERSION_DETAIL="$(xmj_branch_target_detail)"
  xmj_version_write_history
  xmj_version_log_line "结果摘要：$XMJ_VERSION_SUMMARY"
  xmj_version_log_line "结果说明：$XMJ_VERSION_DETAIL"

  xmj_render_version_result \
    'success' \
    'done' \
    "$XMJ_VERSION_SUMMARY" \
    "$XMJ_VERSION_DETAIL"
  return 1
}

xmj_run_version_catalog() {
  local input=''

  XMJ_VERSION_ACTIVE_MODE='version'
  XMJ_VERSION_PAGE='1'
  xmj_version_clear_notice

  if ! xmj_version_refresh_catalog; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  while true; do
    xmj_render_version_list_page
    xmj_version_prompt_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      '')
        xmj_version_set_notice 'warn' '请输入版本序号，或使用 n / p / r / 0。'
        ;;
      0)
        xmj_version_clear_notice
        return 0
        ;;
      n|N)
        if [ "${XMJ_VERSION_PAGE:-1}" -lt "${XMJ_VERSION_TOTAL_PAGES:-1}" ]; then
          XMJ_VERSION_PAGE=$((XMJ_VERSION_PAGE + 1))
          xmj_version_clear_notice
        else
          xmj_version_set_notice 'warn' '已经是最后一页了。'
        fi
        ;;
      p|P)
        if [ "${XMJ_VERSION_PAGE:-1}" -gt 1 ]; then
          XMJ_VERSION_PAGE=$((XMJ_VERSION_PAGE - 1))
          xmj_version_clear_notice
        else
          xmj_version_set_notice 'warn' '已经是第一页了。'
        fi
        ;;
      r|R)
        if ! xmj_version_refresh_catalog; then
          xmj_render_version_result \
            'failure' \
            "$XMJ_VERSION_STAGE" \
            "$XMJ_VERSION_SUMMARY" \
            "$XMJ_VERSION_DETAIL"
          return 1
        fi
        xmj_version_set_notice 'info' '版本列表已刷新。'
        ;;
      *[!0-9]*)
        xmj_version_set_notice 'warn' '仅支持输入版本序号，或使用 n / p / r / 0。'
        ;;
      *)
        xmj_version_clear_notice
        if ! xmj_version_run_switch "$input"; then
          continue
        fi
        return 1
        ;;
    esac
  done
}

xmj_run_branch_catalog() {
  local input=''

  XMJ_VERSION_ACTIVE_MODE='branch'
  XMJ_VERSION_PAGE='1'
  xmj_version_clear_notice

  if ! xmj_branch_refresh_catalog; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 1
  fi

  while true; do
    xmj_render_branch_list_page
    xmj_branch_prompt_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      '')
        xmj_version_set_notice 'warn' '请输入分支序号，或使用 n / p / r / 0。'
        ;;
      0)
        xmj_version_clear_notice
        return 0
        ;;
      n|N)
        if [ "${XMJ_VERSION_PAGE:-1}" -lt "${XMJ_VERSION_TOTAL_PAGES:-1}" ]; then
          XMJ_VERSION_PAGE=$((XMJ_VERSION_PAGE + 1))
          xmj_version_clear_notice
        else
          xmj_version_set_notice 'warn' '已经是最后一页了。'
        fi
        ;;
      p|P)
        if [ "${XMJ_VERSION_PAGE:-1}" -gt 1 ]; then
          XMJ_VERSION_PAGE=$((XMJ_VERSION_PAGE - 1))
          xmj_version_clear_notice
        else
          xmj_version_set_notice 'warn' '已经是第一页了。'
        fi
        ;;
      r|R)
        if ! xmj_branch_refresh_catalog; then
          xmj_render_version_result \
            'failure' \
            "$XMJ_VERSION_STAGE" \
            "$XMJ_VERSION_SUMMARY" \
            "$XMJ_VERSION_DETAIL"
          return 1
        fi
        xmj_version_set_notice 'info' '分支列表已刷新。'
        ;;
      *[!0-9]*)
        xmj_version_set_notice 'warn' '仅支持输入分支序号，或使用 n / p / r / 0。'
        ;;
      *)
        xmj_version_clear_notice
        if ! xmj_branch_run_switch "$input"; then
          continue
        fi
        return 1
        ;;
    esac
  done
}

xmj_run_tavern_version_switch() {
  local input=''

  xmj_version_reset_state

  xmj_render_version_progress \
    'prepare' \
    'running' \
    '准备中' \
    '猫猫正在整理版本抽屉与切换纸条喵~'

  if ! xmj_version_prepare_log_file; then
    xmj_render_version_result \
      'failure' \
      'prepare' \
      '无法创建版本切换日志' \
      '请检查脚本目录的写入权限后再试。'
    return 0
  fi

  xmj_version_log_line '开始执行 03 切换版本 / 分支。'

  xmj_render_version_progress \
    'env' \
    'running' \
    '检查环境' \
    '正在确认路径、Git 和仓库状态。'

  if ! xmj_version_check_environment; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 0
  fi

  if ! xmj_version_check_repository; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 0
  fi

  xmj_version_clear_selector_notice

  while true; do
    xmj_render_switch_mode_page
    xmj_version_prompt_mode_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      '')
        xmj_version_set_selector_notice 'warn' '请选择要切换的类型：1 版本，2 分支，0 返回首页。'
        ;;
      0)
        return 0
        ;;
      1)
        xmj_version_clear_selector_notice
        if xmj_run_version_catalog; then
          continue
        fi
        return 0
        ;;
      2)
        xmj_version_clear_selector_notice
        if xmj_run_branch_catalog; then
          continue
        fi
        return 0
        ;;
      *)
        xmj_version_set_selector_notice 'warn' '这里只支持输入 1 / 2 / 0。'
        ;;
    esac
  done
}
xmj_version_panel_title() {
  case "${XMJ_VERSION_TARGET_KIND:-${XMJ_VERSION_ACTIVE_MODE:-version}}" in
    branch)
      printf '%s' '切换分支'
      ;;
    *)
      printf '%s' '切换版本'
      ;;
  esac
}

xmj_version_panel_phrase() {
  case "${XMJ_VERSION_TARGET_KIND:-${XMJ_VERSION_ACTIVE_MODE:-version}}" in
    branch)
      printf '%s' 'switch branch'
      ;;
    *)
      printf '%s' 'switch version'
      ;;
  esac
}

xmj_render_version_progress() {
  local current_stage="${1:-prepare}"
  local stage_mode="${2:-running}"
  local headline="${3:-准备中}"
  local detail_text="${4:-猫猫正在安静整理切换步骤。}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_version_panel_title)" "$(xmj_version_panel_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$headline" "$detail_text" ''
  printf '\n'
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_version_result() {
  local result_mode="${1:-success}"
  local current_stage="${2:-done}"
  local summary_text="${3:-版本切换已完成。}"
  local detail_text="${4:-}"
  local result_title='切换完成'
  local stage_mode='success'

  if [ "$result_mode" = 'failure' ]; then
    result_title='切换失败'
    stage_mode='failure'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_version_panel_title)" "$(xmj_version_panel_phrase)" 'update'
  printf '\n'
  xmj_render_setting_card "$result_title" "$summary_text" "$detail_text"
  printf '\n'
  printf '  %b♡ 版本切换进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_version_stage_line 'prepare' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'env' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'fetch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'backup' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'local' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'recover' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'restore' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"

  printf '\n'
  if [ -n "${XMJ_VERSION_CURRENT_LABEL:-}" ]; then
    xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL}"
  fi
  if [ -n "${XMJ_VERSION_CURRENT_BRANCH:-}" ]; then
    xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH}"
  fi
  if [ -n "${XMJ_VERSION_CURRENT_COMMIT:-}" ]; then
    xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT}"
  fi
  if [ -n "${XMJ_VERSION_TARGET_DATE:-}" ]; then
    xmj_render_fact_line '发行日期' "${XMJ_VERSION_TARGET_DATE}"
  fi

  xmj_render_page_footer '按回车返回首页'
}

xmj_render_switch_mode_page() {
  local notice_color=''

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '版本 / 分支' 'switch mode' 'update'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  printf '\n'
  xmj_render_setting_card '1 · 切换版本' '按标签切换版本，并显示发行日期。' "推荐：$(xmj_version_recommended_summary)"
  printf '\n'
  xmj_render_setting_card '2 · 切换分支' '按分支切换工作线。' "默认常用：${XMJ_VERSION_RECOMMENDED_BRANCH:-release}"

  if [ -n "${XMJ_VERSION_SELECTOR_NOTICE:-}" ]; then
    notice_color="$(xmj_version_selector_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_SELECTOR_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_render_action_item '1' '进入版本列表'
  xmj_render_action_item '2' '进入分支列表'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 0'
}

xmj_render_version_list_page() {
  local total="${#XMJ_VERSION_TAGS[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '切换版本' 'switch version' 'update'
  printf '\n'
  xmj_render_setting_card '推荐版本' "优先试 $(xmj_version_recommended_summary)。" ''
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"
  xmj_render_fact_line '版本总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步状态' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 可切换版本%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_version_index_marker_text "$index")"
    marker_color="$(xmj_version_index_marker_color "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_TAGS[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "${XMJ_VERSION_TAG_DATES[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一层。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}

xmj_render_branch_list_page() {
  local total="${#XMJ_VERSION_BRANCHES[@]}"
  local page="${XMJ_VERSION_PAGE:-1}"
  local page_size="${XMJ_VERSION_PAGE_SIZE:-12}"
  local total_pages="${XMJ_VERSION_TOTAL_PAGES:-1}"
  local start_index='0'
  local end_index='0'
  local index='0'
  local display_index=''
  local number_width='2'
  local marker_text=''
  local marker_color=''
  local notice_color=''
  local source_text=''

  start_index=$(((page - 1) * page_size))
  end_index=$((start_index + page_size - 1))
  if [ "$end_index" -ge "$total" ]; then
    end_index=$((total - 1))
  fi

  number_width="${#total}"
  if [ "$number_width" -lt 2 ]; then
    number_width='2'
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '切换分支' 'switch branch' 'update'
  printf '\n'
  xmj_render_setting_card '常用分支' "默认常用分支是 ${XMJ_VERSION_RECOMMENDED_BRANCH:-release}。" ''
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_VERSION:-未知}"
  xmj_render_fact_line '当前分支' "${XMJ_VERSION_CURRENT_BRANCH:-detached}"
  xmj_render_fact_line '分支总数' "$total"
  xmj_render_fact_line '当前页' "${page}/${total_pages}"

  if [ -n "${XMJ_VERSION_FETCH_NOTE:-}" ]; then
    xmj_render_fact_line '同步状态' "$XMJ_VERSION_FETCH_NOTE"
  fi

  if [ "${XMJ_VERSION_HAS_LOCAL_CHANGES:-0}" = '1' ] && [ -n "${XMJ_VERSION_LOCAL_NOTE:-}" ]; then
    xmj_render_fact_line '本地改动' "$XMJ_VERSION_LOCAL_NOTE"
  fi

  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
  printf '  %b♡ 可切换分支%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '\n'

  for ((index = start_index; index <= end_index; index += 1)); do
    display_index="$(printf "%0${number_width}d" $((index + 1)))"
    marker_text="$(xmj_branch_index_marker_text "$index")"
    marker_color="$(xmj_branch_index_marker_color "$index")"
    source_text="$(xmj_branch_source_text "$index")"

    printf '  %b[%s]%b %b%s%b %b·%b %b%s%b %b·%b %b%s%b' \
      "$XMJ_PINK" "$display_index" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCHES[$index]}" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_BLUE_SOFT" "$source_text" "$XMJ_RESET" \
      "$XMJ_MIST" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_VERSION_BRANCH_COMMITS[$index]}" "$XMJ_RESET"

    if [ -n "$marker_text" ]; then
      printf ' %b[%s]%b' "$marker_color" "$marker_text" "$XMJ_RESET"
    fi

    printf '\n'
  done

  if [ -n "${XMJ_VERSION_INPUT_NOTICE:-}" ]; then
    notice_color="$(xmj_version_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_INPUT_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回上一层。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '鈹€' 68
}
