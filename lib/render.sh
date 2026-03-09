xmj_section_phrase() {
  local section="${1:-}"

  case "$section" in
    info) printf '%s' 'public memo' ;;
    update) printf '%s' 'update ribbon' ;;
    backup) printf '%s' 'backup lane' ;;
    dependency) printf '%s' 'env notice' ;;
    extend) printf '%s' 'script bloom' ;;
    setting) printf '%s' 'setting room' ;;
    about) printf '%s' 'about neko' ;;
    *) printf '%s' 'preview page' ;;
  esac
}

xmj_render_header() {
  xmj_rule_line "$XMJ_BORDER" '═' 68
  printf '%b%s%b\n' "$XMJ_PINK_SOFT" '                    ╭─⋆˚  小猫卷  ˚⋆─╮' "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_WHITE" '              little panel memory · soft preview' "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_BLUE_SOFT" '               meoroll の preview page · SillyTavern' "$XMJ_RESET"
  printf '%b%s%b\n' "$XMJ_CREAM" '                    Termux Bash Panel Framework' "$XMJ_RESET"
  xmj_rule_line "$XMJ_BORDER" '═' 68
}

xmj_render_info_block() {
  local key

  xmj_render_section_title 'info'
  for key in "${XMJ_INFO_ORDER[@]}"; do
    printf '  %b%s%b｜%b%s%b\n' \
      "$XMJ_BLUE_SOFT" "$key" "$XMJ_RESET" \
      "$XMJ_WHITE" "${XMJ_INFO_VALUE[$key]}" "$XMJ_RESET"
  done
  printf '\n'
}

xmj_render_section_title() {
  local section="${1:-}"
  local decor="${XMJ_SECTION_DECOR[$section]}"
  local title="${XMJ_SECTION_TITLE[$section]}"
  local phrase

  phrase="$(xmj_section_phrase "$section")"

  printf '%b%s%b %b%s%b %b--%b %b%s%b %b× . *%b\n' \
    "$XMJ_PINK" "$decor" "$XMJ_RESET" \
    "$XMJ_BLUE_SOFT" "$phrase" "$XMJ_RESET" \
    "$XMJ_MIST" "$XMJ_RESET" \
    "$XMJ_WHITE" "$title" "$XMJ_RESET" \
    "$XMJ_LAVENDER" "$XMJ_RESET"
}

xmj_render_menu_item() {
  local id="${1:-}"
  printf '%bʚ✞%s✞ɞ%b｜%b%s%b' \
    "$XMJ_PINK" "$id" "$XMJ_RESET" \
    "$XMJ_WHITE" "${XMJ_MENU_LABEL[$id]}" "$XMJ_RESET"
}

xmj_render_menu_row() {
  local left_id="${1:-}"
  local right_id="${2:-}"

  printf '  '
  xmj_render_menu_item "$left_id"

  if [ -n "$right_id" ]; then
    printf '      '
    xmj_render_menu_item "$right_id"
  fi

  printf '\n'
}

xmj_render_menu_block() {
  local section="${1:-}"
  local ids=()
  local id
  local i

  xmj_render_section_title "$section"

  for id in "${XMJ_MENU_IDS[@]}"; do
    if [ "${XMJ_MENU_SECTION[$id]}" = "$section" ]; then
      ids+=("$id")
    fi
  done

  for ((i = 0; i < ${#ids[@]}; i += 2)); do
    xmj_render_menu_row "${ids[$i]}" "${ids[$((i + 1))]:-}"
  done

  printf '\n'
}

xmj_render_input_hint() {
  printf '%b%s%b\n' "$XMJ_BLUE" '  请输入编号跳转页面，输入 00 可退出面板。' "$XMJ_RESET"
}

xmj_render_home() {
  local section

  xmj_clear_screen
  xmj_render_header
  xmj_render_info_block

  for section in "${XMJ_SECTION_ORDER[@]}"; do
    if [ "$section" = 'info' ]; then
      continue
    fi
    xmj_render_menu_block "$section"
  done

  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_render_input_hint
}

xmj_render_placeholder_page() {
  local id="${1:-}"
  local section="${XMJ_MENU_SECTION[$id]}"
  local title="${XMJ_MENU_LABEL[$id]}"

  xmj_clear_screen
  xmj_render_header
  xmj_render_section_title "$section"
  printf '\n'
  printf '  %b当前编号%b：%b%s%b\n' \
    "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_PINK" "$id" "$XMJ_RESET"
  printf '  %b当前页面%b：%b%s%b\n' \
    "$XMJ_BLUE_SOFT" "$XMJ_RESET" "$XMJ_WHITE" "$title" "$XMJ_RESET"
  printf '\n'
  printf '  %b当前功能已预留，暂未实现。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b这里只展示小猫卷的面板框架与占位跳转。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
  printf '  %b不会执行更新、备份、依赖安装、Git 操作等任何真实逻辑。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_rule_line "$XMJ_BORDER" '─' 68
  xmj_wait_for_enter '按回车返回首页'
}

xmj_render_invalid_input() {
  local input="${1:-}"

  printf '\n'
  printf '  %b输入无效%b：%b%s%b\n' \
    "$XMJ_WARN" "$XMJ_RESET" "$XMJ_PINK" "$input" "$XMJ_RESET"
  printf '  %b仅支持输入 00 - 23 的菜单编号。%b\n' "$XMJ_BLUE_SOFT" "$XMJ_RESET"
  xmj_wait_for_enter '按回车返回首页'
}
