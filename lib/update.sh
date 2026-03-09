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
  XMJ_UPDATE_BEFORE_COMMIT=''
  XMJ_UPDATE_AFTER_COMMIT=''
  XMJ_UPDATE_DEPENDENCY_NOTE='依赖阶段尚未开始。'
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

xmj_update_check_environment() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ -z "$repo_path" ]; then
    xmj_update_fail 'env' '未设置酒馆路径' '请先在配置文件里填写 SillyTavern 的真实目录。'
    return 1
  fi

  if [ ! -d "$repo_path" ]; then
    xmj_update_fail 'env' '未找到酒馆目录' "当前路径：$(xmj_display_path "$repo_path")"
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

  repo_flag="$(git -C "$repo_path" rev-parse --is-inside-work-tree 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  if [ "$repo_flag" != 'true' ]; then
    xmj_update_fail 'repo' '目标目录不是 Git 仓库' '请确认这里是通过 Git clone 安装的 SillyTavern 目录。'
    return 1
  fi

  if ! XMJ_UPDATE_BRANCH="$(git -C "$repo_path" symbolic-ref --quiet --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE")"; then
    xmj_update_fail 'repo' '无法识别当前分支' '当前仓库可能处于 detached HEAD，请先手动检查仓库状态。'
    return 1
  fi

  if [ -n "$(git -C "$repo_path" status --porcelain 2>>"$XMJ_UPDATE_LOG_FILE")" ]; then
    xmj_update_fail 'repo' '仓库存在未提交改动' '为避免覆盖本地修改，本次没有继续执行更新。'
    return 1
  fi

  XMJ_UPDATE_BEFORE_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  xmj_update_log_line "当前分支：$XMJ_UPDATE_BRANCH"
  xmj_update_log_line "更新前提交：${XMJ_UPDATE_BEFORE_COMMIT:-unknown}"
  return 0
}

xmj_update_pull_repository() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local upstream_ref=''

  if upstream_ref="$(git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>>"$XMJ_UPDATE_LOG_FILE")"; then
    xmj_update_log_line "检测到上游分支：$upstream_ref"
    if ! git -C "$repo_path" pull --ff-only >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '拉取更新失败' 'Git 没有顺利完成快进更新，请查看日志确认原因。'
      return 1
    fi
  else
    xmj_update_log_line '当前分支未配置上游，尝试使用 origin/<当前分支>。'
    if ! git -C "$repo_path" remote get-url origin >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '未找到可用的远程仓库' '当前分支没有上游，也没有可用的 origin 远程源。'
      return 1
    fi

    if ! git -C "$repo_path" pull --ff-only origin "$XMJ_UPDATE_BRANCH" >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
      xmj_update_fail 'pull' '拉取更新失败' 'Git 没有顺利完成快进更新，请查看日志确认原因。'
      return 1
    fi
  fi

  XMJ_UPDATE_AFTER_COMMIT="$(git -C "$repo_path" rev-parse --short HEAD 2>>"$XMJ_UPDATE_LOG_FILE" || true)"
  xmj_update_log_line "更新后提交：${XMJ_UPDATE_AFTER_COMMIT:-unknown}"
  return 0
}

xmj_update_sync_dependencies() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"

  if [ ! -f "$repo_path/package.json" ]; then
    XMJ_UPDATE_DEPENDENCY_NOTE='仓库中未发现 package.json，已跳过依赖同步。'
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
    xmj_update_fail 'deps' '未检测到 npm' '仓库代码已同步，但当前环境无法继续安装依赖。'
    return 1
  fi

  if ! (
    cd "$repo_path" || exit 1
    npm install --no-audit --no-fund
  ) >>"$XMJ_UPDATE_LOG_FILE" 2>&1; then
    xmj_update_fail 'deps' '依赖同步失败' 'Git 更新已执行，但 npm 没有顺利完成，请查看日志。'
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
    printf '已从 %s 更新到 %s。' "$XMJ_UPDATE_BEFORE_COMMIT" "$XMJ_UPDATE_AFTER_COMMIT"
    return 0
  fi

  printf '%s' '当前已经是最新版本。'
}

xmj_run_tavern_update() {
  xmj_update_reset_state

  xmj_render_update_progress \
    'prepare' \
    'running' \
    '准备更新' \
    '猫猫正在整理更新篮子与日志纸条。' \
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

  xmj_update_log_line '开始执行 01 一键更新酒馆。'

  xmj_render_update_progress \
    'env' \
    'running' \
    '检查环境' \
    '正在确认路径和 Git 环境是否就绪。' \
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

  xmj_render_update_progress \
    'repo' \
    'running' \
    '检查仓库' \
    '正在确认 Git 仓库状态与当前分支。' \
    '' \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

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
    'pull' \
    'running' \
    '拉取更新' \
    '正在使用安全模式同步远程提交。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_pull_repository; then
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
    '正在安静整理依赖内容，请稍等一下。' \
    "$XMJ_UPDATE_BRANCH" \
    "${XMJ_SILLYTAVERN_PATH:-}" \
    "$XMJ_UPDATE_LOG_FILE"

  if ! xmj_update_sync_dependencies; then
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

  XMJ_UPDATE_STAGE='done'
  XMJ_UPDATE_SUMMARY="$(xmj_update_success_summary)"
  XMJ_UPDATE_DETAIL="$XMJ_UPDATE_DEPENDENCY_NOTE"
  xmj_update_log_line "结果摘要：$XMJ_UPDATE_SUMMARY"
  xmj_update_log_line "结果说明：$XMJ_UPDATE_DETAIL"

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
