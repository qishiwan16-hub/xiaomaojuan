XMJ_MAINT_BACKUP_FLOW_RESULT=''
XMJ_MAINT_BACKUP_SELECTED_SCOPE=''
XMJ_BACKUP_SELECT_DATA='0'
XMJ_BACKUP_SELECT_THIRD_PARTY='0'
XMJ_BACKUP_SELECT_CONFIG='0'
XMJ_BACKUP_SELECT_ALL='0'
XMJ_BACKUP_PROGRESS_TITLE=''
XMJ_BACKUP_PROGRESS_STAGE='prepare'
XMJ_BACKUP_PROGRESS_FAILED_STAGE=''
XMJ_BACKUP_PROGRESS_PERCENT='0'
XMJ_BACKUP_PROGRESS_DETAIL=''
XMJ_BACKUP_PROGRESS_SCOPE=''
XMJ_BACKUP_PROGRESS_CURRENT_ITEM=''
XMJ_BACKUP_PROGRESS_CURRENT_STEP='0'
XMJ_BACKUP_PROGRESS_TOTAL_STEPS='0'

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
  XMJ_MAINT_BACKUP_FLOW_RESULT=''
  XMJ_MAINT_BACKUP_SELECTED_SCOPE=''
  XMJ_BACKUP_SELECT_DATA='0'
  XMJ_BACKUP_SELECT_THIRD_PARTY='0'
  XMJ_BACKUP_SELECT_CONFIG='0'
  XMJ_BACKUP_SELECT_ALL='0'
}

xmj_backup_scope_option_label() {
  case "${1:-}" in
    data)
      printf '%s' 'data'
      ;;
    public/scripts/extensions/third-party)
      printf '%s' 'sillytavern/public/scripts/extensions/third-party'
      ;;
    config.yaml)
      printf '%s' 'config.yaml'
      ;;
    all)
      printf '%s' '全选（以上三项）'
      ;;
    *)
      printf '%s' "${1:-未选择}"
      ;;
  esac
}

xmj_backup_scope_mark() {
  if [ "${1:-0}" = '1' ]; then
    printf '%s' '[x]'
    return 0
  fi

  printf '%s' '[ ]'
}

xmj_backup_refresh_all_toggle() {
  if [ "${XMJ_BACKUP_SELECT_DATA:-0}" = '1' ] \
    && [ "${XMJ_BACKUP_SELECT_THIRD_PARTY:-0}" = '1' ] \
    && [ "${XMJ_BACKUP_SELECT_CONFIG:-0}" = '1' ]; then
    XMJ_BACKUP_SELECT_ALL='1'
    return 0
  fi

  XMJ_BACKUP_SELECT_ALL='0'
}

xmj_backup_reset_scope_selection() {
  XMJ_BACKUP_SELECT_DATA='0'
  XMJ_BACKUP_SELECT_THIRD_PARTY='0'
  XMJ_BACKUP_SELECT_CONFIG='0'
  XMJ_BACKUP_SELECT_ALL='0'
}

xmj_backup_apply_default_scope_selection() {
  local compat_reason=''

  xmj_backup_reset_scope_selection
  compat_reason="$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")"
  if [ -n "$compat_reason" ]; then
    XMJ_BACKUP_SELECT_DATA='1'
    xmj_backup_refresh_all_toggle
    return 0
  fi

  XMJ_BACKUP_SELECT_DATA='1'
  XMJ_BACKUP_SELECT_THIRD_PARTY='1'
  XMJ_BACKUP_SELECT_CONFIG='1'
  xmj_backup_refresh_all_toggle
}

xmj_backup_scope_item_exists_text() {
  local repo_path="${1:-}"
  local item="${2:-}"

  if [ -n "$repo_path" ] && { [ -d "$repo_path/$item" ] || [ -f "$repo_path/$item" ]; }; then
    printf '%s' '已发现'
    return 0
  fi

  printf '%s' '当前未发现'
}

xmj_backup_selected_item_lines() {
  if [ "${XMJ_BACKUP_SELECT_DATA:-0}" = '1' ]; then
    printf '%s\n' 'data'
  fi
  if [ "${XMJ_BACKUP_SELECT_THIRD_PARTY:-0}" = '1' ]; then
    printf '%s\n' 'public/scripts/extensions/third-party'
  fi
  if [ "${XMJ_BACKUP_SELECT_CONFIG:-0}" = '1' ]; then
    printf '%s\n' 'config.yaml'
  fi
}

xmj_backup_selected_scope_text() {
  local -a labels=()
  local item=''

  while IFS= read -r item || [ -n "$item" ]; do
    if [ -z "$item" ]; then
      continue
    fi
    labels+=("$(xmj_backup_scope_option_label "$item")")
  done < <(xmj_backup_selected_item_lines)

  if [ "${#labels[@]}" -eq 0 ]; then
    printf '%s' '未选择'
    return 0
  fi

  xmj_backup_join_scope_labels "${labels[@]}"
}

xmj_backup_scope_kind_from_items() {
  if [ "$#" -eq 1 ] && [ "${1:-}" = 'data' ]; then
    printf '%s' 'data-only'
    return 0
  fi

  if [ "$#" -eq 3 ]; then
    printf '%s' 'full'
    return 0
  fi

  printf '%s' 'custom'
}

xmj_backup_toggle_scope_token() {
  case "${1:-}" in
    1|data)
      if [ "${XMJ_BACKUP_SELECT_DATA:-0}" = '1' ]; then
        XMJ_BACKUP_SELECT_DATA='0'
      else
        XMJ_BACKUP_SELECT_DATA='1'
      fi
      ;;
    2|third|third-party)
      if [ "${XMJ_BACKUP_SELECT_THIRD_PARTY:-0}" = '1' ]; then
        XMJ_BACKUP_SELECT_THIRD_PARTY='0'
      else
        XMJ_BACKUP_SELECT_THIRD_PARTY='1'
      fi
      ;;
    3|config|config.yaml)
      if [ "${XMJ_BACKUP_SELECT_CONFIG:-0}" = '1' ]; then
        XMJ_BACKUP_SELECT_CONFIG='0'
      else
        XMJ_BACKUP_SELECT_CONFIG='1'
      fi
      ;;
    4|a|all)
      if [ "${XMJ_BACKUP_SELECT_ALL:-0}" = '1' ]; then
        xmj_backup_reset_scope_selection
      else
        XMJ_BACKUP_SELECT_DATA='1'
        XMJ_BACKUP_SELECT_THIRD_PARTY='1'
        XMJ_BACKUP_SELECT_CONFIG='1'
      fi
      ;;
    *)
      return 1
      ;;
  esac

  xmj_backup_refresh_all_toggle
}

xmj_backup_parse_scope_input() {
  local raw_input="${1:-}"
  local normalized=''
  local compact=''
  local token=''
  local index='0'

  XMJ_BACKUP_SCOPE_ACTION=''
  normalized="${raw_input,,}"

  case "$normalized" in
    y|yes)
      XMJ_BACKUP_SCOPE_ACTION='confirm'
      return 0
      ;;
    s|skip)
      XMJ_BACKUP_SCOPE_ACTION='skip'
      return 0
      ;;
    0)
      XMJ_BACKUP_SCOPE_ACTION='cancel'
      return 0
      ;;
  esac

  normalized="${normalized//,/ }"
  normalized="${normalized//+/ }"
  normalized="${normalized//\// }"
  compact="${normalized//[[:space:]]/}"
  if [ -n "$compact" ] && [[ "$compact" =~ ^[1-4]+$ ]]; then
    for ((index = 0; index < ${#compact}; index += 1)); do
      token="${compact:index:1}"
      if ! xmj_backup_toggle_scope_token "$token"; then
        return 1
      fi
    done
    XMJ_BACKUP_SCOPE_ACTION='toggle'
    return 0
  fi

  if [ -z "$normalized" ]; then
    return 1
  fi

  for token in $normalized; do
    if ! xmj_backup_toggle_scope_token "$token"; then
      return 1
    fi
  done

  XMJ_BACKUP_SCOPE_ACTION='toggle'
}

xmj_backup_prompt_scope_input() {
  if [ "${1:-0}" = '1' ]; then
    printf '%b%s%b' "$XMJ_PINK_SOFT" '  输入 1 / 2 / 3 / 4 / y / s / 0 > ' "$XMJ_RESET"
  else
    printf '%b%s%b' "$XMJ_PINK_SOFT" '  输入 1 / 2 / 3 / 4 / y / 0 > ' "$XMJ_RESET"
  fi
  IFS= read -r XMJ_LAST_INPUT
}

xmj_render_backup_scope_page() {
  local repo_path="${1:-}"
  local op_name="${2:-创建备份}"
  local current_version="${3:-}"
  local target_version="${4:-}"
  local allow_skip="${5:-0}"
  local compat_reason=''

  compat_reason="$(xmj_maintenance_data_only_backup_reason "$current_version" "$target_version")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '备份范围' 'backup scope' 'backup'
  printf '\n'

  if [ -n "$compat_reason" ]; then
    xmj_render_setting_card \
      "$op_name" \
      "${compat_reason}，这里会先让你选择这次要打进 zip 的内容。" \
      '默认先勾选 data；如果你确认需要，也可以继续勾选 third-party 或 config.yaml。'
  else
    xmj_render_setting_card \
      "$op_name" \
      '这里会先确认这次要进入 zip 压缩包的备份范围。' \
      '只会打包你当前勾选的内容，未勾选的部分不会进入这次备份。'
  fi

  printf '\n'
  xmj_render_fact_line '备份目录' "$(xmj_display_path "$(xmj_maintenance_backup_dir)")"
  xmj_render_fact_line '压缩格式' '.zip'
  xmj_render_fact_line '当前选择' "$(xmj_backup_selected_scope_text)"

  if [ -n "$compat_reason" ]; then
    printf '\n'
    printf '  %b%s%b\n' "$XMJ_WARN" "$(xmj_maintenance_cross_version_notice)" "$XMJ_RESET"
  fi

  xmj_render_backup_notice
  printf '\n'
  printf '  %b♡ 备份项%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_action_item '1' "$(xmj_backup_scope_mark "$XMJ_BACKUP_SELECT_DATA") data · $(xmj_backup_scope_item_exists_text "$repo_path" 'data')"
  xmj_render_action_item '2' "$(xmj_backup_scope_mark "$XMJ_BACKUP_SELECT_THIRD_PARTY") sillytavern/public/scripts/extensions/third-party · $(xmj_backup_scope_item_exists_text "$repo_path" 'public/scripts/extensions/third-party')"
  xmj_render_action_item '3' "$(xmj_backup_scope_mark "$XMJ_BACKUP_SELECT_CONFIG") config.yaml · $(xmj_backup_scope_item_exists_text "$repo_path" 'config.yaml')"
  xmj_render_action_item '4' "$(xmj_backup_scope_mark "$XMJ_BACKUP_SELECT_ALL") 全选（以上三项）"
  printf '\n'
  xmj_render_action_item 'y' '确认这次备份范围并继续'
  if [ "$allow_skip" = '1' ]; then
    xmj_render_action_item 's' '跳过备份并继续当前操作'
  fi
  xmj_render_action_item '0' '取消并返回上一页'
  xmj_render_action_footer '可以反复输入 1 / 2 / 3 / 4 调整范围；输入 1 2、1,2 或 123 也能一次切多项。'
}

xmj_backup_run_scope_picker() {
  local repo_path="${1:-}"
  local op_name="${2:-创建备份}"
  local current_version="${3:-}"
  local target_version="${4:-}"
  local allow_skip="${5:-0}"
  local input=''

  xmj_backup_clear_notice
  xmj_backup_apply_default_scope_selection "$current_version" "$target_version"

  while true; do
    xmj_render_backup_scope_page "$repo_path" "$op_name" "$current_version" "$target_version" "$allow_skip"
    xmj_backup_prompt_scope_input "$allow_skip"
    input="${XMJ_LAST_INPUT:-}"

    if ! xmj_backup_parse_scope_input "$input"; then
      if [ "$allow_skip" = '1' ]; then
        xmj_backup_set_notice 'warn' '这里只支持输入 1 / 2 / 3 / 4 / y / s / 0。'
      else
        xmj_backup_set_notice 'warn' '这里只支持输入 1 / 2 / 3 / 4 / y / 0。'
      fi
      continue
    fi

    case "${XMJ_BACKUP_SCOPE_ACTION:-}" in
      confirm)
        if [ "$(xmj_backup_selected_scope_text)" = '未选择' ]; then
          xmj_backup_set_notice 'warn' '至少勾选一项备份内容后，才能继续生成压缩包。'
          continue
        fi
        XMJ_MAINT_BACKUP_FLOW_RESULT='selected'
        XMJ_MAINT_BACKUP_SELECTED_SCOPE="$(xmj_backup_selected_scope_text)"
        return 0
        ;;
      skip)
        if [ "$allow_skip" != '1' ]; then
          xmj_backup_set_notice 'warn' '这个入口需要先确认备份范围，不能直接跳过备份。'
          continue
        fi
        XMJ_MAINT_BACKUP_FLOW_RESULT='skipped'
        XMJ_MAINT_BACKUP_NOTE='这次按你的选择跳过了备份。'
        XMJ_MAINT_BACKUP_SELECTED_SCOPE='未选择'
        return 0
        ;;
      cancel)
        XMJ_MAINT_BACKUP_FLOW_RESULT='cancelled'
        return 2
        ;;
    esac
  done
}

xmj_backup_progress_reset() {
  XMJ_BACKUP_PROGRESS_TITLE=''
  XMJ_BACKUP_PROGRESS_STAGE='prepare'
  XMJ_BACKUP_PROGRESS_FAILED_STAGE=''
  XMJ_BACKUP_PROGRESS_PERCENT='0'
  XMJ_BACKUP_PROGRESS_DETAIL=''
  XMJ_BACKUP_PROGRESS_SCOPE=''
  XMJ_BACKUP_PROGRESS_CURRENT_ITEM=''
  XMJ_BACKUP_PROGRESS_CURRENT_STEP='0'
  XMJ_BACKUP_PROGRESS_TOTAL_STEPS='0'
}

xmj_backup_progress_stage_order() {
  case "${1:-prepare}" in
    prepare) printf '%s' '1' ;;
    collect) printf '%s' '2' ;;
    archive) printf '%s' '3' ;;
    done) printf '%s' '4' ;;
    *) printf '%s' '0' ;;
  esac
}

xmj_backup_progress_stage_label() {
  case "${1:-prepare}" in
    prepare) printf '%s' '准备阶段' ;;
    collect) printf '%s' '收集文件' ;;
    archive) printf '%s' '打包压缩' ;;
    done) printf '%s' '完成' ;;
    *) printf '%s' '处理中' ;;
  esac
}

xmj_backup_progress_stage_state() {
  local stage_id="${1:-prepare}"
  local current_stage="${XMJ_BACKUP_PROGRESS_STAGE:-prepare}"
  local failed_stage="${XMJ_BACKUP_PROGRESS_FAILED_STAGE:-}"
  local stage_order='0'
  local current_order='0'
  local failed_order='0'

  stage_order="$(xmj_backup_progress_stage_order "$stage_id")"
  current_order="$(xmj_backup_progress_stage_order "$current_stage")"

  if [ -n "$failed_stage" ]; then
    failed_order="$(xmj_backup_progress_stage_order "$failed_stage")"
    if [ "$stage_order" -lt "$failed_order" ]; then
      printf '%s' 'done'
      return 0
    fi
    if [ "$stage_id" = "$failed_stage" ]; then
      printf '%s' 'failure'
      return 0
    fi
    printf '%s' 'pending'
    return 0
  fi

  if [ "$current_stage" = 'done' ]; then
    printf '%s' 'done'
    return 0
  fi

  if [ "$stage_order" -lt "$current_order" ]; then
    printf '%s' 'done'
    return 0
  fi

  if [ "$stage_id" = "$current_stage" ]; then
    printf '%s' 'running'
    return 0
  fi

  printf '%s' 'pending'
}

xmj_render_backup_progress_stage_line() {
  local stage_id="${1:-prepare}"
  local stage_label=''
  local stage_state=''
  local mark=''
  local color=''

  stage_label="$(xmj_backup_progress_stage_label "$stage_id")"
  stage_state="$(xmj_backup_progress_stage_state "$stage_id")"

  case "$stage_state" in
    done)
      mark='√'
      color="$XMJ_CREAM"
      ;;
    running)
      mark='➜'
      color="$XMJ_PINK"
      ;;
    failure)
      mark='×'
      color="$XMJ_WARN"
      ;;
    *)
      mark='·'
      color="$XMJ_MIST"
      ;;
  esac

  printf '  %b%s%b %s\n' "$color" "$mark" "$XMJ_RESET" "$stage_label"
}

xmj_render_backup_progress_page() {
  local progress_bar=''

  progress_bar="$(xmj_backup_progress_bar_text "${XMJ_BACKUP_PROGRESS_PERCENT:-0}" '28')"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '备份处理中' 'backup progress' 'backup'
  printf '\n'
  xmj_render_setting_card \
    "${XMJ_BACKUP_PROGRESS_TITLE:-生成备份}" \
    "${XMJ_BACKUP_PROGRESS_DETAIL:-猫猫正在处理这次备份。}" \
    ''
  printf '\n'
  printf '  %b♡ 进度条%b\n' "$XMJ_PINK" "$XMJ_RESET"
  printf '  %b[%s]%b %b%s%%%b\n' \
    "$XMJ_BLUE_SOFT" "$progress_bar" "$XMJ_RESET" \
    "$XMJ_WHITE" "${XMJ_BACKUP_PROGRESS_PERCENT:-0}" "$XMJ_RESET"
  xmj_render_fact_line '当前阶段' "$(xmj_backup_progress_stage_label "${XMJ_BACKUP_PROGRESS_STAGE:-prepare}")"
  if [ "${XMJ_BACKUP_PROGRESS_TOTAL_STEPS:-0}" -gt 0 ]; then
    xmj_render_fact_line '处理进度' "${XMJ_BACKUP_PROGRESS_CURRENT_STEP:-0} / ${XMJ_BACKUP_PROGRESS_TOTAL_STEPS:-0}"
  fi
  if [ -n "${XMJ_BACKUP_PROGRESS_CURRENT_ITEM:-}" ]; then
    xmj_render_fact_line '当前条目' "${XMJ_BACKUP_PROGRESS_CURRENT_ITEM}"
  fi
  if [ -n "${XMJ_BACKUP_PROGRESS_SCOPE:-}" ]; then
    xmj_render_fact_line '备份范围' "${XMJ_BACKUP_PROGRESS_SCOPE}"
  fi
  printf '\n'
  printf '  %b♡ 备份小进度%b\n' "$XMJ_PINK" "$XMJ_RESET"
  xmj_render_backup_progress_stage_line 'prepare'
  xmj_render_backup_progress_stage_line 'collect'
  xmj_render_backup_progress_stage_line 'archive'
  xmj_render_backup_progress_stage_line 'done'
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '-' 68
}

xmj_backup_progress_begin() {
  XMJ_BACKUP_PROGRESS_TITLE="${1:-生成备份}"
  XMJ_BACKUP_PROGRESS_SCOPE="${2:-}"
  XMJ_BACKUP_PROGRESS_FAILED_STAGE=''
  XMJ_BACKUP_PROGRESS_CURRENT_ITEM=''
  XMJ_BACKUP_PROGRESS_CURRENT_STEP='0'
  XMJ_BACKUP_PROGRESS_TOTAL_STEPS='0'
  XMJ_BACKUP_PROGRESS_STAGE='prepare'
  XMJ_BACKUP_PROGRESS_PERCENT='3'
  XMJ_BACKUP_PROGRESS_DETAIL='正在准备这次备份要用到的目录和元信息。'
  xmj_render_backup_progress_page
}

xmj_backup_progress_show_prepare() {
  XMJ_BACKUP_PROGRESS_STAGE='prepare'
  XMJ_BACKUP_PROGRESS_PERCENT='10'
  XMJ_BACKUP_PROGRESS_DETAIL="${1:-正在准备这次备份要用到的目录和元信息。}"
  xmj_render_backup_progress_page
}

xmj_backup_progress_collect_percent() {
  local current="${1:-0}"
  local total="${2:-0}"

  if [ "$total" -le 0 ]; then
    printf '%s' '35'
    return 0
  fi

  printf '%s' $((12 + (current * 23 / total)))
}

xmj_backup_progress_show_collect() {
  local current="${1:-0}"
  local total="${2:-0}"
  local current_item="${3:-}"
  local detail_text="${4:-正在整理这次要进入 zip 的文件范围。}"

  XMJ_BACKUP_PROGRESS_STAGE='collect'
  XMJ_BACKUP_PROGRESS_PERCENT="$(xmj_backup_progress_collect_percent "$current" "$total")"
  XMJ_BACKUP_PROGRESS_DETAIL="$detail_text"
  XMJ_BACKUP_PROGRESS_CURRENT_ITEM="$current_item"
  XMJ_BACKUP_PROGRESS_CURRENT_STEP="$current"
  XMJ_BACKUP_PROGRESS_TOTAL_STEPS="$total"
  xmj_render_backup_progress_page
}

xmj_backup_progress_archive_percent() {
  local current="${1:-0}"
  local total="${2:-0}"

  if [ "$total" -le 0 ]; then
    printf '%s' '96'
    return 0
  fi

  if [ "$current" -gt "$total" ]; then
    current="$total"
  fi

  if [ "$current" -ge "$total" ]; then
    printf '%s' '96'
    return 0
  fi

  printf '%s' $((40 + (current * 56 / total)))
}

xmj_backup_progress_show_archive() {
  local current="${1:-0}"
  local total="${2:-0}"
  local current_item="${3:-}"
  local detail_text="${4:-正在把勾选内容写进 zip 压缩包。}"

  XMJ_BACKUP_PROGRESS_STAGE='archive'
  XMJ_BACKUP_PROGRESS_PERCENT="$(xmj_backup_progress_archive_percent "$current" "$total")"
  XMJ_BACKUP_PROGRESS_DETAIL="$detail_text"
  XMJ_BACKUP_PROGRESS_CURRENT_ITEM="$current_item"
  XMJ_BACKUP_PROGRESS_CURRENT_STEP="$current"
  XMJ_BACKUP_PROGRESS_TOTAL_STEPS="$total"
  xmj_render_backup_progress_page
}

xmj_backup_progress_show_done() {
  XMJ_BACKUP_PROGRESS_STAGE='done'
  XMJ_BACKUP_PROGRESS_PERCENT='100'
  XMJ_BACKUP_PROGRESS_DETAIL="${1:-备份压缩包已经准备完成。}"
  XMJ_BACKUP_PROGRESS_CURRENT_ITEM=''
  xmj_render_backup_progress_page
}

xmj_backup_progress_show_failure() {
  XMJ_BACKUP_PROGRESS_FAILED_STAGE="${1:-archive}"
  XMJ_BACKUP_PROGRESS_STAGE="${1:-archive}"
  XMJ_BACKUP_PROGRESS_DETAIL="${2:-这次备份没有顺利完成，请先查看日志。}"
  xmj_render_backup_progress_page
}

xmj_backup_count_path_entries() {
  local path_value="${1:-}"
  local entry_count='0'

  if [ -f "$path_value" ]; then
    printf '%s' '1'
    return 0
  fi

  if [ ! -d "$path_value" ]; then
    printf '%s' '0'
    return 0
  fi

  entry_count="$(find "$path_value" -mindepth 0 2>/dev/null | awk 'END {print NR+0}')"
  entry_count="$(xmj_backup_normalize_bytes "$entry_count")"
  printf '%s' "$entry_count"
}

xmj_maintenance_zip_archive_with_progress() {
  local repo_path="${1:-}"
  local archive_file="${2:-}"
  local shell_log="${3:-/dev/null}"
  local meta_file="${4:-}"
  local total_entries="${5:-0}"
  local fifo_root=''
  local fifo_file=''
  local zip_pid=''
  local status='0'
  local line=''
  local completed='0'
  local entry_name=''
  shift 5
  local -a items=("$@")

  fifo_root="$(mktemp -d "$(dirname "$archive_file")/.xmj-zip-progress-XXXXXX" 2>/dev/null || true)"
  if [ -z "$fifo_root" ]; then
    fifo_root="$(dirname "$archive_file")/.xmj-zip-progress-$$"
    mkdir -p "$fifo_root" 2>/dev/null || return 1
  fi

  fifo_file="$fifo_root/output.fifo"
  if ! mkfifo "$fifo_file" 2>/dev/null; then
    rm -rf "$fifo_root" 2>/dev/null || true
    return 1
  fi

  (
    cd "$repo_path" || exit 1
    LC_ALL=C zip -0r "$archive_file" "${items[@]}"
    LC_ALL=C zip -0j "$archive_file" "$meta_file"
  ) >"$fifo_file" 2>&1 &
  zip_pid="$!"

  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line" >>"$shell_log"
    case "$line" in
      adding:\ *|updating:\ *)
        completed=$((completed + 1))
        if [ "$completed" -gt "$total_entries" ]; then
          completed="$total_entries"
        fi
        entry_name="${line#*: }"
        entry_name="${entry_name%% (*}"
        xmj_backup_progress_show_archive "$completed" "$total_entries" "$entry_name"
        ;;
    esac
  done <"$fifo_file"

  wait "$zip_pid"
  status=$?
  rm -rf "$fifo_root" 2>/dev/null || true
  return "$status"
}

xmj_maintenance_python_archive_with_progress() {
  local repo_path="${1:-}"
  local archive_file="${2:-}"
  local shell_log="${3:-/dev/null}"
  local meta_file="${4:-}"
  local total_entries="${5:-0}"
  local python_cmd=''
  local fifo_root=''
  local fifo_file=''
  local job_pid=''
  local status='0'
  local line=''
  local completed='0'
  shift 5
  local -a items=("$@")

  python_cmd="$(xmj_maintenance_python_cmd)"
  if [ -z "$python_cmd" ]; then
    return 1
  fi

  fifo_root="$(mktemp -d "$(dirname "$archive_file")/.xmj-py-progress-XXXXXX" 2>/dev/null || true)"
  if [ -z "$fifo_root" ]; then
    fifo_root="$(dirname "$archive_file")/.xmj-py-progress-$$"
    mkdir -p "$fifo_root" 2>/dev/null || return 1
  fi

  fifo_file="$fifo_root/output.fifo"
  if ! mkfifo "$fifo_file" 2>/dev/null; then
    rm -rf "$fifo_root" 2>/dev/null || true
    return 1
  fi

  "$python_cmd" - "$repo_path" "$archive_file" "$meta_file" "${items[@]}" >"$fifo_file" 2>&1 <<'PY' &
import os
import sys
import zipfile

repo_path, archive_file, meta_file, *items = sys.argv[1:]
with zipfile.ZipFile(archive_file, "w", compression=zipfile.ZIP_STORED) as zf:
    zf.write(meta_file, os.path.basename(meta_file))
    print(f"ENTRY\t{os.path.basename(meta_file)}", flush=True)
    for item in items:
        item_path = os.path.join(repo_path, item)
        if not os.path.exists(item_path):
            continue
        if os.path.isdir(item_path):
            for current_root, _, filenames in os.walk(item_path):
                rel_root = os.path.relpath(current_root, repo_path)
                zf.write(current_root, rel_root)
                print(f"ENTRY\t{rel_root}", flush=True)
                for filename in filenames:
                    file_path = os.path.join(current_root, filename)
                    arcname = os.path.relpath(file_path, repo_path)
                    zf.write(file_path, arcname)
                    print(f"ENTRY\t{arcname}", flush=True)
        else:
            zf.write(item_path, item)
            print(f"ENTRY\t{item}", flush=True)
PY
  job_pid="$!"

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == ENTRY$'\t'* ]]; then
      completed=$((completed + 1))
      if [ "$completed" -gt "$total_entries" ]; then
        completed="$total_entries"
      fi
      xmj_backup_progress_show_archive "$completed" "$total_entries" "${line#ENTRY$'\t'}"
      continue
    fi

    printf '%s\n' "$line" >>"$shell_log"
  done <"$fifo_file"

  wait "$job_pid"
  status=$?
  rm -rf "$fifo_root" 2>/dev/null || true
  return "$status"
}

xmj_maintenance_create_archive_with_progress() {
  local repo_path="${1:-}"
  local archive_file="${2:-}"
  local shell_log="${3:-/dev/null}"
  local meta_file="${4:-}"
  local total_entries="${5:-0}"
  shift 5

  if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    xmj_maintenance_zip_archive_with_progress "$repo_path" "$archive_file" "$shell_log" "$meta_file" "$total_entries" "$@"
    return $?
  fi

  xmj_maintenance_python_archive_with_progress "$repo_path" "$archive_file" "$shell_log" "$meta_file" "$total_entries" "$@"
}

xmj_maintenance_backup_scope_text() {
  printf '%s' 'data / sillytavern/public/scripts/extensions/third-party / config.yaml（可选）'
}

xmj_maintenance_backup_stage_text() {
  local reason_text=''

  reason_text="$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")"
  if [ -n "$reason_text" ]; then
    printf '%s' "${reason_text}，接下来会先进入统一备份选择页，默认勾选 data。"
    return 0
  fi

  printf '%s' '接下来会先选择这次要打进 zip 的范围，再开始实际备份。'
}

xmj_maintenance_backup_preview_note() {
  local reason_text=''

  reason_text="$(xmj_maintenance_data_only_backup_reason "${1:-}" "${2:-}")"
  if [ -n "$reason_text" ]; then
    printf '%s' "${reason_text}，备份选择页会默认先勾选 data；third-party 和 config.yaml 仍然可以手动加选。"
    return 0
  fi

  printf '%s' '可以自由勾选 data、third-party 和 config.yaml；只会把本次勾选的内容打成 1 个 zip。'
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
  local temp_root=''
  local meta_file=''
  local current_version=''
  local compat_reason=''
  local joined_selected=''
  local joined_items=''
  local joined_missing=''
  local scan_total='0'
  local scan_done='0'
  local total_entries='1'
  local item=''
  local item_entries='0'
  local action_text=''
  shift 6
  local -a requested_items=("$@")
  local -a selected_labels=()
  local -a item_labels=()
  local -a missing_labels=()
  local -a items=()

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
    XMJ_MAINT_BACKUP_COMPAT_MODE='1'
    XMJ_MAINT_BACKUP_COMPAT_NOTE="$(xmj_maintenance_cross_version_notice)"
  else
    XMJ_MAINT_BACKUP_COMPAT_MODE='0'
    XMJ_MAINT_BACKUP_COMPAT_NOTE=''
  fi

  if [ "${#requested_items[@]}" -eq 0 ]; then
    if [ -n "$compat_reason" ]; then
      requested_items=('data')
    else
      requested_items=('data' 'public/scripts/extensions/third-party' 'config.yaml')
    fi
  fi

  for item in "${requested_items[@]}"; do
    selected_labels+=("$(xmj_backup_scope_option_label "$item")")
    if [ -d "$repo_path/$item" ] || [ -f "$repo_path/$item" ]; then
      items+=("$item")
      item_labels+=("$(xmj_backup_scope_option_label "$item")")
    else
      missing_labels+=("$(xmj_backup_scope_option_label "$item")")
    fi
  done

  joined_selected="$(xmj_backup_join_scope_labels "${selected_labels[@]}")"
  joined_items="$(xmj_backup_join_scope_labels "${item_labels[@]}")"
  joined_missing="$(xmj_backup_join_scope_labels "${missing_labels[@]}")"
  XMJ_MAINT_BACKUP_SELECTED_SCOPE="$joined_selected"
  XMJ_MAINT_BACKUP_ITEMS="$joined_items"
  XMJ_MAINT_BACKUP_MISSING_ITEMS="$joined_missing"
  XMJ_MAINT_BACKUP_SCOPE="$(xmj_backup_scope_kind_from_items "${items[@]}")"

  backup_dir="$(xmj_maintenance_backup_dir)"
  if ! mkdir -p "$backup_dir" 2>/dev/null; then
    XMJ_MAINT_LAST_ERROR="无法创建备份目录：$backup_dir"
    return 1
  fi

  archive_name="$(xmj_maintenance_timestamp).zip"
  archive_file="$backup_dir/$archive_name"
  XMJ_MAINT_BACKUP_DIR="$backup_dir"
  XMJ_MAINT_BACKUP_NAME="$archive_name"

  if [ "${#items[@]}" -eq 0 ]; then
    XMJ_MAINT_BACKUP_FILE=''
    XMJ_MAINT_BACKUP_NOTE="这次勾选的是 ${joined_selected}，但当前目录里没有找到可打包内容，所以没有生成新的备份压缩包。"
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
    return 0
  fi

  if ! xmj_maintenance_require_archive_tools; then
    return 1
  fi

  rm -f "$archive_file" 2>/dev/null || true
  temp_root="$(mktemp -d "$backup_dir/.xmj-backup-XXXXXX" 2>/dev/null || true)"
  if [ -z "$temp_root" ]; then
    temp_root="$backup_dir/.xmj-backup-$$"
    mkdir -p "$temp_root" 2>/dev/null || {
      XMJ_MAINT_LAST_ERROR='无法准备备份临时目录。'
      return 1
    }
  fi

  if ! xmj_maintenance_write_backup_meta "$temp_root"; then
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='无法写入备份元信息。'
    return 1
  fi

  meta_file="$temp_root/$(xmj_maintenance_backup_meta_name)"
  action_text="生成${op_name}备份"
  xmj_maintenance_log "$logger_name" "开始为${op_name}生成备份：${joined_selected}"
  xmj_backup_progress_begin "$action_text" "$joined_selected"
  xmj_backup_progress_show_prepare '正在准备备份目录、元信息和压缩包输出位置。'

  scan_total="${#requested_items[@]}"
  for item in "${requested_items[@]}"; do
    scan_done=$((scan_done + 1))
    if [ -d "$repo_path/$item" ] || [ -f "$repo_path/$item" ]; then
      item_entries="$(xmj_backup_count_path_entries "$repo_path/$item")"
      total_entries=$((total_entries + item_entries))
      xmj_backup_progress_show_collect "$scan_done" "$scan_total" "$(xmj_backup_scope_option_label "$item")" '正在收集本次要进入 zip 的文件范围。'
    else
      xmj_backup_progress_show_collect "$scan_done" "$scan_total" "$(xmj_backup_scope_option_label "$item")" '这个选项当前没有找到，会在打包时自动跳过。'
    fi
  done

  if ! xmj_maintenance_create_archive_with_progress "$repo_path" "$archive_file" "$shell_log" "$meta_file" "$total_entries" "${items[@]}"; then
    xmj_backup_progress_show_failure 'archive' '打包压缩阶段没有完成，请先查看对应日志。'
    rm -f "$archive_file" 2>/dev/null || true
    rm -rf "$temp_root" 2>/dev/null || true
    XMJ_MAINT_LAST_ERROR='生成备份压缩包失败，请先查看日志。'
    return 1
  fi

  rm -rf "$temp_root" 2>/dev/null || true
  xmj_backup_progress_show_done '备份压缩包已经准备完成。'

  XMJ_MAINT_BACKUP_FILE="$archive_file"
  if [ -n "$joined_missing" ]; then
    XMJ_MAINT_BACKUP_NOTE="已把 ${joined_items} 打成 1 个 zip 备份；这次没有找到 ${joined_missing}。"
  else
    XMJ_MAINT_BACKUP_NOTE="已把 ${joined_items} 打成 1 个 zip 备份。"
  fi

  xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_NOTE"
  if [ -n "${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}" ]; then
    xmj_maintenance_log "$logger_name" "$XMJ_MAINT_BACKUP_COMPAT_NOTE"
  fi
  return 0
}

xmj_maintenance_run_backup_flow() {
  local repo_path="${1:-}"
  local logger_name="${2:-}"
  local log_file="${3:-}"
  local op_name="${4:-创建备份}"
  local current_version="${5:-}"
  local target_version="${6:-}"
  local allow_skip="${7:-0}"
  local picker_status='0'
  local create_status='0'
  local item=''
  local -a selected_items=()

  xmj_maintenance_clear_state
  if ! xmj_backup_run_scope_picker "$repo_path" "$op_name" "$current_version" "$target_version" "$allow_skip"; then
    picker_status=$?
    if [ "$picker_status" -eq 2 ]; then
      return 2
    fi
    return 1
  fi

  if [ "${XMJ_MAINT_BACKUP_FLOW_RESULT:-}" = 'skipped' ]; then
    return 0
  fi

  while IFS= read -r item || [ -n "$item" ]; do
    if [ -z "$item" ]; then
      continue
    fi
    selected_items+=("$item")
  done < <(xmj_backup_selected_item_lines)

  xmj_maintenance_create_backup "$repo_path" "$logger_name" "$log_file" "$op_name" "$current_version" "$target_version" "${selected_items[@]}"
  create_status=$?
  if [ "$create_status" -ne 0 ]; then
    return "$create_status"
  fi

  if [ -n "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
    XMJ_MAINT_BACKUP_FLOW_RESULT='created'
  else
    XMJ_MAINT_BACKUP_FLOW_RESULT='empty'
  fi

  return 0
}

xmj_render_compat_notice_card() {
  local mode="${1:-switch}"
  local summary_text=''

  case "$mode" in
    update)
      summary_text="如果当前版本低于 $(xmj_maintenance_compat_floor_version)，备份选择页会默认先勾选 data。"
      ;;
    *)
      summary_text="如果当前版本或目标版本低于 $(xmj_maintenance_compat_floor_version)，备份选择页会默认先勾选 data。"
      ;;
  esac

  xmj_render_setting_card \
    '低版本兼容提醒' \
    "$summary_text" \
    'third-party 和 config.yaml 仍然可以按需手动加选；恢复时会按压缩包里的实际内容覆盖回来。'
}

xmj_render_version_compat_confirm_page() {
  local reason_text="${1:-}"
  local notice_color=''

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title '切换版本' 'switch version' 'update'
  printf '\n'
  xmj_render_setting_card \
    '切换前确认' \
    "${reason_text}，接下来会先进入统一备份选择页，默认勾选 data。" \
    '如果你确认需要，也可以在备份选择页里继续加选 third-party 或 config.yaml。'
  printf '\n'
  xmj_render_fact_line '当前版本' "${XMJ_VERSION_CURRENT_LABEL:-未知}"
  xmj_render_fact_line '目标版本' "${XMJ_VERSION_TARGET_TAG:-未知}"
  xmj_render_fact_line '发布日期' "${XMJ_VERSION_TARGET_DATE:-未知}"

  if [ -n "${XMJ_VERSION_CONFIRM_NOTICE:-}" ]; then
    notice_color="$(xmj_version_confirm_notice_color)"
    printf '\n'
    printf '  %b%s%b\n' "$notice_color" "$XMJ_VERSION_CONFIRM_NOTICE" "$XMJ_RESET"
  fi

  printf '\n'
  xmj_render_action_item 'y' '确认继续这次版本切换'
  xmj_render_action_item '0' '取消并返回版本列表'
  xmj_render_action_footer '输入 y / 0。'
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
    '恢复时会按压缩包里的实际内容覆盖回来；如果这是低版本兼容备份，压缩包里可能只包含 data。'
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

xmj_update_run_backup() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local status='0'

  xmj_maintenance_run_backup_flow \
    "$repo_path" \
    'xmj_update_log_line' \
    "$XMJ_UPDATE_LOG_FILE" \
    '安装更新' \
    "${XMJ_UPDATE_BEFORE_VERSION:-}" \
    '' \
    '0'
  status=$?

  case "$status" in
    0)
      XMJ_UPDATE_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
      XMJ_UPDATE_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
      XMJ_UPDATE_BACKUP_COMPAT_NOTE="${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}"
      return 0
      ;;
    2)
      xmj_update_fail 'backup' '已取消安装更新' '你取消了这次备份范围选择，所以更新没有继续。'
      return 1
      ;;
    *)
      xmj_update_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成 zip 备份。}"
      return 1
      ;;
  esac
}

xmj_version_run_backup() {
  local repo_path="${XMJ_SILLYTAVERN_PATH:-}"
  local status='0'

  xmj_maintenance_run_backup_flow \
    "$repo_path" \
    'xmj_version_log_line' \
    "$XMJ_VERSION_LOG_FILE" \
    '版本切换' \
    "${XMJ_VERSION_BEFORE_VERSION:-}" \
    "${XMJ_VERSION_TARGET_TAG:-}" \
    '0'
  status=$?

  case "$status" in
    0)
      XMJ_VERSION_BACKUP_FILE="$XMJ_MAINT_BACKUP_FILE"
      XMJ_VERSION_BACKUP_NOTE="$XMJ_MAINT_BACKUP_NOTE"
      XMJ_VERSION_BACKUP_COMPAT_NOTE="${XMJ_MAINT_BACKUP_COMPAT_NOTE:-}"
      return 0
      ;;
    2)
      xmj_version_fail 'backup' '已取消版本切换' '你取消了这次备份范围选择，所以版本切换没有继续。'
      return 1
      ;;
    *)
      xmj_version_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成 zip 备份。}"
      return 1
      ;;
  esac
}

xmj_run_backup_create_page() {
  local status='0'

  xmj_backup_clear_notice
  xmj_maintenance_run_backup_flow "$XMJ_SILLYTAVERN_PATH" '' '' '手动备份' '' '' '0'
  status=$?

  case "$status" in
    0)
      if [ -n "${XMJ_MAINT_BACKUP_FILE:-}" ]; then
        xmj_render_backup_create_result \
          'success' \
          '手动备份已经打包完成。' \
          "${XMJ_MAINT_BACKUP_NOTE:-已经生成 1 个 zip 备份包。}"
        return 0
      fi

      xmj_render_backup_create_result \
        'success' \
        '这次没有生成新的备份压缩包。' \
        "${XMJ_MAINT_BACKUP_NOTE:-当前没有可打包的备份内容。}"
      return 0
      ;;
    2)
      return 0
      ;;
    *)
      xmj_render_backup_create_result \
        'failure' \
        '手动备份没有顺利完成。' \
        "${XMJ_MAINT_LAST_ERROR:-请检查当前目录与权限。}"
      return 0
      ;;
  esac
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
    printf '  %b• 继续后会进入统一备份选择页，你可以勾选 data、third-party、config.yaml，或直接全选。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '  %b• 如果这次不想备份，也可以在下一页直接选择跳过备份并继续。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
    printf '\n'
    printf '  %b输入 y：继续到备份选择；输入 0：取消。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
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
  xmj_rule_line "$XMJ_BORDER" '路' 68
}

xmj_reinstall_prompt_backup_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  y 继续 / 0 取消 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_run_tavern_uninstall_flow() {
  local history_note=''
  local status='0'

  XMJ_REINSTALL_BACKUP_FILE=''
  XMJ_REINSTALL_BACKUP_ENABLED='0'

  if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
    xmj_maintenance_run_backup_flow \
      "$XMJ_SILLYTAVERN_PATH" \
      'xmj_reinstall_log_line' \
      "$XMJ_REINSTALL_LOG_FILE" \
      '卸载酒馆' \
      "${XMJ_REINSTALL_BEFORE_VERSION:-}" \
      '' \
      '1'
    status=$?

    case "$status" in
      0)
        XMJ_REINSTALL_BACKUP_FILE="${XMJ_MAINT_BACKUP_FILE:-}"
        XMJ_REINSTALL_BACKUP_NOTE="${XMJ_MAINT_BACKUP_NOTE:-}"
        if [ "${XMJ_MAINT_BACKUP_FLOW_RESULT:-}" = 'created' ]; then
          XMJ_REINSTALL_BACKUP_ENABLED='1'
        fi
        ;;
      2)
        xmj_reinstall_fail 'backup' '已取消这次操作' '你取消了备份范围选择，所以这次卸载没有继续。'
        xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
        return 0
        ;;
      *)
        xmj_reinstall_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成备份压缩包。}"
        xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
        return 0
        ;;
    esac
  else
    XMJ_REINSTALL_BACKUP_NOTE='当前没有旧酒馆目录，这次没有备份内容。'
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
  local status='0'

  XMJ_REINSTALL_BACKUP_FILE=''
  XMJ_REINSTALL_BACKUP_ENABLED='0'

  if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" = '1' ]; then
    xmj_maintenance_run_backup_flow \
      "$XMJ_SILLYTAVERN_PATH" \
      'xmj_reinstall_log_line' \
      "$XMJ_REINSTALL_LOG_FILE" \
      '重装酒馆' \
      "${XMJ_REINSTALL_BEFORE_VERSION:-}" \
      '' \
      '1'
    status=$?

    case "$status" in
      0)
        XMJ_REINSTALL_BACKUP_FILE="${XMJ_MAINT_BACKUP_FILE:-}"
        XMJ_REINSTALL_BACKUP_NOTE="${XMJ_MAINT_BACKUP_NOTE:-}"
        if [ "${XMJ_MAINT_BACKUP_FLOW_RESULT:-}" = 'created' ]; then
          XMJ_REINSTALL_BACKUP_ENABLED='1'
        fi
        ;;
      2)
        xmj_reinstall_fail 'backup' '已取消这次操作' '你取消了备份范围选择，所以这次重装没有继续。'
        xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
        return 0
        ;;
      *)
        xmj_reinstall_fail 'backup' '自动备份失败' "${XMJ_MAINT_LAST_ERROR:-未能顺利生成备份压缩包。}"
        xmj_render_reinstall_result 'failure' "$XMJ_REINSTALL_STAGE" "$XMJ_REINSTALL_SUMMARY" "$XMJ_REINSTALL_DETAIL"
        return 0
        ;;
    esac
  else
    XMJ_REINSTALL_BACKUP_NOTE='当前没有旧酒馆目录，这次没有备份内容。'
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
    XMJ_REINSTALL_DETAIL="$(xmj_reinstall_append_detail "$XMJ_REINSTALL_DETAIL" '备份压缩包已保留，可以稍后继续处理。')"
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
      '正在把备份压缩包里的内容覆盖恢复回来。'

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
        if [ "${XMJ_REINSTALL_CAN_BACKUP:-0}" != '1' ]; then
          XMJ_REINSTALL_BACKUP_ENABLED='0'
          XMJ_REINSTALL_BACKUP_NOTE='当前没有旧酒馆目录，这次没有备份内容。'
        fi
        break
        ;;
      0)
        return 0
        ;;
      *)
        XMJ_REINSTALL_CONFIRM_NOTICE='这里只支持输入 y / 0。'
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
