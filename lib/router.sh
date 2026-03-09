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
    01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23)
      xmj_render_placeholder_page "$input"
      return 0
      ;;
    *)
      xmj_render_invalid_input "$input"
      return 0
      ;;
  esac
}

xmj_prompt_input() {
  printf '%b%s%b' "$XMJ_PINK_SOFT" '  请输入菜单编号 > ' "$XMJ_RESET"
  IFS= read -r XMJ_LAST_INPUT
}

xmj_run_panel() {
  local input

  xmj_load_menu_data

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
