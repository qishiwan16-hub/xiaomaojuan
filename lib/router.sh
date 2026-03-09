xmj_exit_panel() {
  xmj_clear_screen
  xmj_render_header
  printf '\n'
  printf '  %b小猫卷预览框架已退出。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b当前版本仅包含 UI 面板与占位跳转，不包含任何真实业务逻辑。%b\n' "$XMJ_CREAM" "$XMJ_RESET"
  printf '\n'
}

xmj_handle_route() {
  local input="${1:-}"

  case "$input" in
    00)
      xmj_exit_panel
      return 1
      ;;
    18)
      xmj_run_script_setting_page
      return 0
      ;;
    01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23)
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
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  设置操作 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_handle_script_setting_action() {
  local input="${1:-}"

  case "$input" in
    ''|0)
      xmj_font_clear_notice
      return 1
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

  return 0
}

xmj_run_script_setting_page() {
  local input

  xmj_font_clear_notice

  while true; do
    xmj_render_script_setting_page
    xmj_prompt_script_setting_input
    input="${XMJ_LAST_INPUT:-}"

    if ! xmj_handle_script_setting_action "$input"; then
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
