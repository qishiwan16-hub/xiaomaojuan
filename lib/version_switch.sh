xmj_version_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown-time'
  fi

  printf '%s' "$timestamp"
}

xmj_version_reset_state() {
  XMJ_VERSION_LOG_FILE=''
  XMJ_VERSION_STAGE='prepare'
  XMJ_VERSION_SUMMARY=''
  XMJ_VERSION_DETAIL=''
  XMJ_VERSION_HAS_LOCAL_CHANGES='0'
  XMJ_VERSION_LOCAL_NOTE=''
  XMJ_VERSION_FETCH_NOTE=''
  XMJ_VERSION_DEPENDENCY_NOTE=''
  XMJ_VERSION_STASH_CREATED='0'
  XMJ_VERSION_STASH_REF=''
  XMJ_VERSION_STASH_LABEL=''
  XMJ_VERSION_RESTORE_NOTE=''
  XMJ_VERSION_CURRENT_LABEL=''
  XMJ_VERSION_CURRENT_TAG=''
  XMJ_VERSION_CURRENT_COMMIT=''
  XMJ_VERSION_TARGET_TAG=''
  XMJ_VERSION_TARGET_DATE=''
  XMJ_VERSION_TARGET_COMMIT=''
  XMJ_VERSION_INPUT_NOTICE=''
  XMJ_VERSION_INPUT_NOTICE_KIND='info'
  XMJ_VERSION_PAGE='1'
  XMJ_VERSION_PAGE_SIZE='12'
  XMJ_VERSION_TOTAL_PAGES='1'
  XMJ_VERSION_RECOMMENDED_PRIMARY_TAG=''
  XMJ_VERSION_RECOMMENDED_SECONDARY_TAG=''

  declare -ga XMJ_VERSION_TAGS=()
  declare -ga XMJ_VERSION_TAG_DATES=()
  declare -ga XMJ_VERSION_TAG_COMMITS=()
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

  XMJ_VERSION_CURRENT_TAG=''
  XMJ_VERSION_CURRENT_LABEL='未知状态'
  XMJ_VERSION_CURRENT_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_VERSION_LOG_FILE" || true)"

  exact_tag="$(git -C "$repo_path" describe --tags --exact-match 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  if [ -n "$exact_tag" ]; then
    XMJ_VERSION_CURRENT_TAG="$exact_tag"
    XMJ_VERSION_CURRENT_LABEL="$exact_tag"
    return 0
  fi

  branch_name="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_VERSION_LOG_FILE" || true)"
  if [ -n "$branch_name" ]; then
    XMJ_VERSION_CURRENT_LABEL="分支：$branch_name"
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

xmj_version_stage_order() {
  case "${1:-}" in
    prepare) printf '%s' '1' ;;
    env) printf '%s' '2' ;;
    fetch) printf '%s' '3' ;;
    switch) printf '%s' '4' ;;
    deps) printf '%s' '5' ;;
    done) printf '%s' '6' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_version_stage_label() {
  case "${1:-}" in
    prepare) printf '%s' '准备中' ;;
    env) printf '%s' '检查环境' ;;
    fetch) printf '%s' '整理版本列表' ;;
    switch) printf '%s' '切换版本' ;;
    deps) printf '%s' '同步依赖' ;;
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
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
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
  xmj_render_version_stage_line 'switch' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'deps' "$current_stage" "$stage_mode"
  xmj_render_version_stage_line 'done' "$current_stage" "$stage_mode"

  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '当前提交' "${XMJ_VERSION_CURRENT_COMMIT:-unknown}"

  if [ -n "${XMJ_VERSION_TARGET_DATE:-}" ]; then
    xmj_render_fact_line '发行日期' "${XMJ_VERSION_TARGET_DATE}"
  fi

  if [ -n "${XMJ_VERSION_LOG_FILE:-}" ]; then
    xmj_render_fact_line '日志' "$(xmj_display_path "$XMJ_VERSION_LOG_FILE")"
  fi

  xmj_render_page_footer '按回车返回首页'
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
    '输入对应序号即可切换，n / p 翻页，r 刷新版本列表，0 返回首页。'
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
  printf '  %b输入序号即可切换；n 下一页；p 上一页；r 刷新；0 返回首页。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
}

xmj_version_prompt_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  版本序号 / n / p / r / 0 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_version_target_detail() {
  local detail_text=''

  detail_text="发行日期：${XMJ_VERSION_TARGET_DATE:-unknown-date}。"
  detail_text="${detail_text} 当前会停留在标签版本上，后续若要继续跟随更新，建议再切回主分支。"

  case "${XMJ_VERSION_RESTORE_NOTE:-}" in
    ''|'无需放回本地改动。')
      ;;
    *)
      detail_text="${detail_text} ${XMJ_VERSION_RESTORE_NOTE}"
      ;;
  esac

  printf '%s' "$detail_text"
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
  XMJ_VERSION_TARGET_DATE="$target_date"

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

  if [ "${XMJ_VERSION_STASH_CREATED:-0}" = '1' ]; then
    if ! xmj_version_restore_local_changes; then
      xmj_version_log_line '版本已切换成功，但本地改动未自动放回。'
    fi
  fi

  XMJ_VERSION_STAGE='done'
  XMJ_VERSION_SUMMARY="已切换到 ${XMJ_VERSION_CURRENT_LABEL:-$target_tag}"
  XMJ_VERSION_DETAIL="$(xmj_version_target_detail)"
  xmj_version_log_line "结果摘要：$XMJ_VERSION_SUMMARY"
  xmj_version_log_line "结果说明：$XMJ_VERSION_DETAIL"

  xmj_render_version_result \
    'success' \
    'done' \
    "$XMJ_VERSION_SUMMARY" \
    "$XMJ_VERSION_DETAIL"
  return 1
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

  xmj_version_log_line '开始执行 03 切换版本。'

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

  if ! xmj_version_refresh_catalog; then
    xmj_render_version_result \
      'failure' \
      "$XMJ_VERSION_STAGE" \
      "$XMJ_VERSION_SUMMARY" \
      "$XMJ_VERSION_DETAIL"
    return 0
  fi

  while true; do
    xmj_render_version_list_page
    xmj_version_prompt_input
    input="${XMJ_LAST_INPUT:-}"

    case "$input" in
      '' )
        xmj_version_set_notice 'warn' '请输入版本序号，或使用 n / p / r / 0。'
        ;;
      0)
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
          return 0
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
        return 0
        ;;
    esac
  done
}
