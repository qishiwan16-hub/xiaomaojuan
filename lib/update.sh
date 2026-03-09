xmj_update_timestamp() {
  local timestamp=''

  timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [ -z "$timestamp" ]; then
    timestamp='unknown-time'
  fi

  printf '%s' "$timestamp"
}

xmj_update_reset_state() {
  XMJ_UPDATE_LOG_FILE=''
  XMJ_UPDATE_STAGE='prepare'
  XMJ_UPDATE_SUMMARY=''
  XMJ_UPDATE_DETAIL=''
  XMJ_UPDATE_BRANCH=''
  XMJ_UPDATE_BEFORE_VERSION=''
  XMJ_UPDATE_AFTER_VERSION=''
  XMJ_UPDATE_BEFORE_COMMIT=''
  XMJ_UPDATE_AFTER_COMMIT=''
  XMJ_UPDATE_DEPENDENCY_NOTE=''
  XMJ_UPDATE_BACKUP_FILE=''
  XMJ_UPDATE_BACKUP_NOTE=''
  XMJ_UPDATE_RECOVER_NOTE=''
  XMJ_UPDATE_HAS_LOCAL_CHANGES='0'
  XMJ_UPDATE_LOCAL_NOTE=''
  XMJ_UPDATE_STASH_CREATED='0'
  XMJ_UPDATE_STASH_REF=''
  XMJ_UPDATE_STASH_LABEL=''
  XMJ_UPDATE_RESTORE_NOTE=''
}

xmj_update_log_line() {
  local line="${1:-}"

  if [ -z "${XMJ_UPDATE_LOG_FILE:-}" ] || [ -z "$line" ]; then
    return 0
  fi

  printf '[%s] %s\n' "$(xmj_update_timestamp)" "$line" >>"$XMJ_UPDATE_LOG_FILE"
}

xmj_update_prepare_log_file() {
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

  XMJ_UPDATE_LOG_FILE="$XMJ_LOG_DIR/update-$stamp.log"
  if ! : >"$XMJ_UPDATE_LOG_FILE" 2>/dev/null; then
    return 1
  fi

  xmj_update_log_line '小猫卷更新日志已创建。'
  xmj_update_log_line "目标目录：${XMJ_SILLYTAVERN_PATH:-未设置}"
  return 0
}

xmj_update_fail() {
  local stage="${1:-repo}"
  local summary="${2:-更新失败}"
  local detail="${3:-请查看日志文件。}"

  XMJ_UPDATE_STAGE="$stage"
  XMJ_UPDATE_SUMMARY="$summary"
  XMJ_UPDATE_DETAIL="$detail"

  xmj_update_log_line "失败阶段：$stage"
  xmj_update_log_line "失败摘要：$summary"
  xmj_update_log_line "失败说明：$detail"
  return 1
}

xmj_update_append_detail() {
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

xmj_update_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ -z "$repo_path" ]; then
    xmj_update_fail 'env' '未设置酒馆路径' '请先在配置里填写 SillyTavern 目录。'
    return 1
  fi

  if [ ! -d "$repo_path" ]; then
    xmj_update_fail 'env' '未找到酒馆目录' '请先确认配置里的 SillyTavern 目录是否正确。'
    return 1
  fi

  if ! command -v git >/dev/null 2>&1; then
    xmj_update_fail 'env' '未检测到 Git' '请先在 Termux 中安装 git 后再试。'
    return 1
  fi

  xmj_update_log_line '环境检查通过。'
  xmj_update_log_line "Git 版本：$(git --version 2>/dev/null || printf '%s' 'unknown')"
  return 0
}

xmj_update_check_repository() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local repo_flag=''
  local worktree_state=''

  repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  if [ "$repo_flag" != 'true' ]; then
    xmj_update_fail 'repo' '目标目录不是 Git 仓库' '请确认这里是通过 Git clone 安装的 SillyTavern 目录。'
    return 1
  fi

  if ! XMJ_UPDATE_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE")"; then
    xmj_update_fail 'repo' '无法识别当前分支' '当前仓库状态暂时无法直接更新。'
    return 1
  fi

  XMJ_UPDATE_BEFORE_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$XMJ_UPDATE_LOG_FILE")"
  XMJ_UPDATE_BEFORE_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  worktree_state="$(git -C "$repo_path" status --porcelain 2>>"$XMJ_UPDATE_LOG_FILE" || true)"

  if [ -n "$worktree_state" ]; then
    XMJ_UPDATE_HAS_LOCAL_CHANGES='1'
    XMJ_UPDATE_LOCAL_NOTE='检测到本地改动，更新前会先临时收好。'
    xmj_update_log_line '检测到本地改动，将在更新前自动 stash。'
    printf '%s\n' "$worktree_state" >>"$XMJ_UPDATE_LOG_FILE"
  else
    XMJ_UPDATE_HAS_LOCAL_CHANGES='0'
    XMJ_UPDATE_LOCAL_NOTE='工作区干净，无需整理本地改动。'
    xmj_update_log_line "$XMJ_UPDATE_LOCAL_NOTE"
  fi

  xmj_update_log_line "当前分支：$XMJ_UPDATE_BRANCH"
  xmj_update_log_line "更新前提交：${XMJ_UPDATE_BEFORE_COMMIT:-unknown}"
  return 0
}

xmj_update_prepare_local_changes() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local stash_before=''
  local stash_after=''
  local stash_stamp=''

  if [ "${XMJ_UPDATE_HAS_LOCAL_CHANGES:-0}" != '1' ]; then
    XMJ_UPDATE_LOCAL_NOTE='本地改动无需整理。'
    xmj_update_log_line "$XMJ_UPDATE_LOCAL_NOTE"
    return 0
  fi

  stash_before="$(git -C "$repo_path" rev-parse --verify -q refs/stash 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  stash_stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stash_stamp" ]; then
    stash_stamp='manual'
  fi

  XMJ_UPDATE_STASH_LABEL="xmj-auto-update-$stash_stamp"
  xmj_update_log_line "开始整理本地改动：${XMJ_UPDATE_STASH_LABEL}"

  if ! git -C "$repo_path" stash push --include-untracked -m "$XMJ_UPDATE_STASH_LABEL" >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
    xmj_update_fail 'local' '整理本地改动失败' '未能临时收好本地改动，本次更新已停止。'
    return 1
  fi

  stash_after="$(git -C "$repo_path" rev-parse --verify -q refs/stash 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  if [ -z "$stash_after" ] || [ "$stash_after" = "$stash_before" ]; then
    xmj_update_fail 'local' '整理本地改动失败' '检测到本地改动，但没有成功生成临时保存记录。'
    return 1
  fi

  XMJ_UPDATE_STASH_CREATED='1'
  XMJ_UPDATE_STASH_REF='stash@{0}'
  XMJ_UPDATE_LOCAL_NOTE='本地改动已临时收好。'
  xmj_update_log_line "$XMJ_UPDATE_LOCAL_NOTE"
  return 0
}

xmj_update_run_backup() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if ! xmj_maintenance_create_backup "$repo_path" 'xmj_update_log_line' "$XMJ_UPDATE_LOG_FILE" '一键更新'; then
    xmj_update_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成 zip 备份。}"
    return 1
  fi

  XMJ_UPDATE_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
  XMJ_UPDATE_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
  return 0
}

xmj_update_run_recover() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if ! xmj_maintenance_restore_backup "$repo_path" 'xmj_update_log_line' "$XMJ_UPDATE_LOG_FILE"; then
    xmj_update_fail 'recover' '恢复备份失败' "${XMJ_MAINT_LAST_ERROR:-备份压缩包没有顺利恢复。}"
    return 1
  fi

  XMJ_UPDATE_RECOVER_NOTE="$XMJ_MAINT_BACKUP_RESTORE_NOTE"
  return 0
}

xmj_update_restore_local_changes() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ "${XMJ_UPDATE_STASH_CREATED:-0}" != '1' ]; then
    XMJ_UPDATE_RESTORE_NOTE='无需放回本地改动。'
    xmj_update_log_line "$XMJ_UPDATE_RESTORE_NOTE"
    return 0
  fi

  xmj_update_log_line "开始放回本地改动：${XMJ_UPDATE_STASH_REF}"
  if git -C "$repo_path" stash pop --index "$XMJ_UPDATE_STASH_REF" >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
    XMJ_UPDATE_STASH_CREATED='0'
    XMJ_UPDATE_STASH_REF=''
    XMJ_UPDATE_RESTORE_NOTE='本地改动已自动放回。'
    xmj_update_log_line "$XMJ_UPDATE_RESTORE_NOTE"
    return 0
  fi

  XMJ_UPDATE_RESTORE_NOTE='本地改动没有顺利自动放回。'
  xmj_update_fail 'restore' '本地改动未自动放回' '原始改动仍保存在临时记录里，可温和查看日志。'
  return 1
}

xmj_update_pull_repository() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local upstream_ref=''

  if upstream_ref="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>>"$XMJ_UPDATE_LOG_FILE")"; then
    xmj_update_log_line "检测到上游分支：$upstream_ref"
    if ! git -C "$repo_path" pull --ff-only >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '拉取更新失败' '远程内容没有顺利同步，可温和查看日志。'
      return 1
    fi
  else
    xmj_update_log_line '当前分支未配置上游，尝试使用 origin/<当前分支>。'
    if ! git -C "$repo_path" remote get-url origin >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '未找到可用的远程仓库' '没有找到可用的远程更新来源。'
      return 1
    fi

    if ! git -C "$repo_path" pull --ff-only origin "$XMJ_UPDATE_BRANCH" >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '拉取更新失败' '远程内容没有顺利同步，可温和查看日志。'
      return 1
    fi
  fi

  XMJ_UPDATE_AFTER_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  XMJ_UPDATE_AFTER_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$XMJ_UPDATE_LOG_FILE")"
  xmj_update_log_line "更新后提交：${XMJ_UPDATE_AFTER_COMMIT:-unknown}"
  xmj_update_log_line "更新后版本：${XMJ_UPDATE_AFTER_VERSION:-unknown}"
  return 0
}

xmj_update_sync_dependencies() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ ! -f "$repo_path/package.json" ]; then
    XMJ_UPDATE_DEPENDENCY_NOTE='未发现 package.json，已跳过依赖同步。'
    xmj_update_log_line "$XMJ_UPDATE_DEPENDENCY_NOTE"
    return 0
  fi

  if [ -n "${XMJ_UPDATE_BEFORE_COMMIT:-}" ] \
    && [ -n "${XMJ_UPDATE_AFTER_COMMIT:-}" ] \
    && [ "$XMJ_UPDATE_BEFORE_COMMIT" = "$XMJ_UPDATE_AFTER_COMMIT" ]; then
    XMJ_UPDATE_DEPENDENCY_NOTE='当前已是最新提交，本次跳过依赖同步。'
    xmj_update_log_line "$XMJ_UPDATE_DEPENDENCY_NOTE"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    xmj_update_fail 'deps' '未检测到 npm' '代码已同步，但当前环境无法完成依赖整理。'
    return 1
  fi

  if ! (
    cd "$repo_path" || exit 1
    npm install --no-audit --no-fund
  ) >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
    xmj_update_fail 'deps' '同步依赖失败' '依赖整理没有顺利完成，可温和查看日志。'
    return 1
  fi

  XMJ_UPDATE_DEPENDENCY_NOTE='依赖同步已完成。'
  xmj_update_log_line "$XMJ_UPDATE_DEPENDENCY_NOTE"
  return 0
}

xmj_update_success_summary() {
  if [ -n "${XMJ_UPDATE_BEFORE_COMMIT:-}" ] \
    && [ -n "${XMJ_UPDATE_AFTER_COMMIT:-}" ] \
    && [ "$XMJ_UPDATE_BEFORE_COMMIT" != "$XMJ_UPDATE_AFTER_COMMIT" ]; then
    printf '%s' '已更新完成。'
    return 0
  fi

  printf '%s' '当前已是最新版本。'
}

xmj_update_success_detail() {
  local detail_text=''

  if [ -n "${XMJ_UPDATE_BACKUP_NOTE:-}" ]; then
    detail_text="$(xmj_update_append_detail "$detail_text" "$XMJ_UPDATE_BACKUP_NOTE")"
  fi

  if [ -n "${XMJ_UPDATE_RECOVER_NOTE:-}" ]; then
    detail_text="$(xmj_update_append_detail "$detail_text" "$XMJ_UPDATE_RECOVER_NOTE")"
  fi

  if [ -n "${XMJ_UPDATE_RESTORE_NOTE:-}" ] \
    && [ "$XMJ_UPDATE_RESTORE_NOTE" = '本地改动已自动放回。' ]; then
    detail_text="$(xmj_update_append_detail "$detail_text" "$XMJ_UPDATE_RESTORE_NOTE")"
  fi

  printf '%s' "$detail_text"
}

xmj_update_write_history() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local action_kind=''
  local note_text=''

  action_kind="$(xmj_maintenance_classify_change "$repo_path" "${XMJ_UPDATE_BEFORE_COMMIT:-}" "${XMJ_UPDATE_AFTER_COMMIT:-}" "$XMJ_UPDATE_LOG_FILE")"
  if [ -z "$action_kind" ]; then
    xmj_update_log_line '本次没有产生新的版本变化，跳过写入更新记录。'
    return 0
  fi

  if [ -z "${XMJ_UPDATE_AFTER_VERSION:-}" ]; then
    XMJ_UPDATE_AFTER_VERSION="$(xmj_maintenance_repo_version "$repo_path" "$XMJ_UPDATE_LOG_FILE")"
  fi

  note_text="分支：${XMJ_UPDATE_BRANCH:-unknown}。提交：${XMJ_UPDATE_BEFORE_COMMIT:-unknown} -> ${XMJ_UPDATE_AFTER_COMMIT:-unknown}。"
  if ! xmj_maintenance_record_history "$action_kind" "${XMJ_UPDATE_AFTER_VERSION:-未知}" "$note_text" 'xmj_update_log_line'; then
    xmj_update_log_line "更新记录写入失败：${XMJ_MAINT_LAST_ERROR:-unknown}"
  fi

  return 0
}

xmj_run_tavern_update() {
  xmj_update_reset_state

  xmj_render_update_progress \
    'prepare' \
    'running' \
    '准备中' \
    '猫猫正在收拾更新篮子与日志纸条。' \
    '' \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    ''

  if ! xmj_update_prepare_log_file; then
    xmj_render_update_result \
      'failure' \
      'prepare' \
      '无法创建更新日志' \
      '请检查脚本目录的写入权限后再试。' \
      '' \
      '' \
      '' \
      '' \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_update_log_line '开始执行 02 一键更新。'

  xmj_render_update_progress \
    'env' \
    'running' \
    '检查环境' \
    '正在确认路径、Git 和仓库状态。' \
    '' \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_check_environment; then
    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  if ! xmj_update_check_repository; then
    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_render_update_progress \
    'backup' \
    'running' \
    '自动备份' \
    '正在把 data、third-party 和 config.yaml 打包成 zip 备份。'

  if ! xmj_update_run_backup; then
    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_render_update_progress \
    'local' \
    'running' \
    '整理本地改动' \
    '若检测到未提交内容，会先轻轻收进临时口袋。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_prepare_local_changes; then
    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_render_update_progress \
    'pull' \
    'running' \
    '拉取更新' \
    '正在同步远程新内容。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_pull_repository; then
    if [ -n "${XMJ_UPDATE_BACKUP_FILE:-}" ]; then
      xmj_render_update_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '更新没有完成，先把自动备份的内容覆盖恢复回来。' \
        "$XMJ_UPDATE_BRANCH" \
        "${XMJ_SILLYTAVERN_PATH:-}" \
        "$XMJ_UPDATE_LOG_FILE"

      if xmj_update_run_recover; then
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" "$XMJ_UPDATE_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_UPDATE_STASH_CREATED:-0}" = '1' ]; then
      xmj_render_update_progress \
        'restore' \
        'running' \
        '放回本地改动' \
        '更新没有完成，先把刚才收好的内容放回去。' \
        "$XMJ_UPDATE_BRANCH" \
        "${XMJ_SILLYTAVERN_PATH:-}" \
        "$XMJ_UPDATE_LOG_FILE"

      if xmj_update_restore_local_changes; then
        XMJ_UPDATE_STAGE='pull'
        XMJ_UPDATE_SUMMARY='拉取更新失败'
        XMJ_UPDATE_DETAIL='远程内容没有顺利同步。'
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" "${XMJ_UPDATE_RECOVER_NOTE:-}")"
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" '本地改动已自动放回。可查看日志。')"
        xmj_update_log_line "失败后恢复说明：$XMJ_UPDATE_DETAIL"
      fi
    fi

    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_render_update_progress \
    'deps' \
    'running' \
    '同步依赖' \
    '需要时会安静补齐依赖内容。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_sync_dependencies; then
    if [ -n "${XMJ_UPDATE_BACKUP_FILE:-}" ]; then
      xmj_render_update_progress \
        'recover' \
        'running' \
        '恢复备份' \
        '依赖整理没有完成，先把自动备份的内容覆盖恢复回来。' \
        "$XMJ_UPDATE_BRANCH" \
        "${XMJ_SILLYTAVERN_PATH:-}" \
        "$XMJ_UPDATE_LOG_FILE"

      if xmj_update_run_recover; then
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" "$XMJ_UPDATE_RECOVER_NOTE")"
      fi
    fi

    if [ "${XMJ_UPDATE_STASH_CREATED:-0}" = '1' ]; then
      xmj_render_update_progress \
        'restore' \
        'running' \
        '放回本地改动' \
        '依赖整理没有完成，先把刚才收好的内容放回去。' \
        "$XMJ_UPDATE_BRANCH" \
        "${XMJ_SILLYTAVERN_PATH:-}" \
        "$XMJ_UPDATE_LOG_FILE"

      if xmj_update_restore_local_changes; then
        XMJ_UPDATE_STAGE='deps'
        XMJ_UPDATE_SUMMARY='同步依赖失败'
        XMJ_UPDATE_DETAIL='依赖整理没有完成。'
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" "${XMJ_UPDATE_RECOVER_NOTE:-}")"
        XMJ_UPDATE_DETAIL="$(xmj_update_append_detail "$XMJ_UPDATE_DETAIL" '本地改动已自动放回。可查看日志。')"
        xmj_update_log_line "失败后恢复说明：$XMJ_UPDATE_DETAIL"
      fi
    fi

    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  xmj_render_update_progress \
    'recover' \
    'running' \
    '恢复备份' \
    '代码与依赖已经更新完成，正在把自动备份的内容覆盖恢复回来。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_run_recover; then
    xmj_render_update_result \
      'failure' \
      "$XMJ_UPDATE_STAGE" \
      "$XMJ_UPDATE_SUMMARY" \
      "$XMJ_UPDATE_DETAIL" \
      "$XMJ_UPDATE_BRANCH" \
      "$XMJ_UPDATE_BEFORE_COMMIT" \
      "$XMJ_UPDATE_AFTER_COMMIT" \
      "$XMJ_UPDATE_LOG_FILE" \
      "${XMJ_SILLYTAVERN_PATH:-}"
    return 0
  fi

  if [ "${XMJ_UPDATE_STASH_CREATED:-0}" = '1' ]; then
    xmj_render_update_progress \
      'restore' \
      'running' \
      '放回本地改动' \
      '正在把刚才收好的内容放回原位。' \
      "$XMJ_UPDATE_BRANCH" \
      "${XMJ_SILLYTAVERN_PATH:-}" \
      "$XMJ_UPDATE_LOG_FILE"

    if ! xmj_update_restore_local_changes; then
      xmj_render_update_result \
        'failure' \
        "$XMJ_UPDATE_STAGE" \
        "$XMJ_UPDATE_SUMMARY" \
        "$XMJ_UPDATE_DETAIL" \
        "$XMJ_UPDATE_BRANCH" \
        "$XMJ_UPDATE_BEFORE_COMMIT" \
        "$XMJ_UPDATE_AFTER_COMMIT" \
        "$XMJ_UPDATE_LOG_FILE" \
        "${XMJ_SILLYTAVERN_PATH:-}"
      return 0
    fi
  fi

  XMJ_UPDATE_STAGE='done'
  XMJ_UPDATE_SUMMARY="$(xmj_update_success_summary)"
  XMJ_UPDATE_DETAIL="$(xmj_update_success_detail)"
  xmj_update_write_history
  xmj_update_log_line "结果摘要：$XMJ_UPDATE_SUMMARY"
  if [ -n "$XMJ_UPDATE_DETAIL" ]; then
    xmj_update_log_line "结果说明：$XMJ_UPDATE_DETAIL"
  fi

  xmj_render_update_result \
    'success' \
    "$XMJ_UPDATE_STAGE" \
    "$XMJ_UPDATE_SUMMARY" \
    "$XMJ_UPDATE_DETAIL" \
    "$XMJ_UPDATE_BRANCH" \
    "$XMJ_UPDATE_BEFORE_COMMIT" \
    "$XMJ_UPDATE_AFTER_COMMIT" \
    "$XMJ_UPDATE_LOG_FILE" \
    "${XMJ_SILLYTAVERN_PATH:-}"

  return 0
}
