xmj_exit_panel() {
  xmj_clear_screen
  xmj_render_header
  printf '\n'
  printf '  %b小猫卷面板已退出。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b当前仅 02 一键更新已接入真实流程，其余功能仍在整理中。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
  printf '\n'
}

xmj_handle_route() {
  local input="${1:-}"

  case "$input" in
    00)
      xmj_exit_panel
      return 1
      ;;
    02)
      xmj_run_tavern_update
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
      xmj_run_script_setting_page 'basic'
      return 0
      ;;
    01|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18)
      xmj_render_menu_page "$input"
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

xmj_handle_script_setting_action() {
  local view="${1:-home}"
  local input="${2:-}"

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
          XMJ_SETTING_NEXT_VIEW='basic'
          ;;
        2)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='theme'
          ;;
        3)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='font'
          ;;
        4)
          xmj_font_clear_notice
          XMJ_SETTING_NEXT_VIEW='advanced'
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 4 / 0。'
          ;;
      esac
      ;;
    basic|theme|advanced)
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
