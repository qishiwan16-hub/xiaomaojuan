xmj_init_font_state() {
  XMJ_FONT_ACTION_MESSAGE=''
  XMJ_FONT_ACTION_LEVEL='info'
}

xmj_font_set_notice() {
  XMJ_FONT_ACTION_LEVEL="${1:-info}"
  XMJ_FONT_ACTION_MESSAGE="${2:-}"
}

xmj_font_clear_notice() {
  XMJ_FONT_ACTION_MESSAGE=''
  XMJ_FONT_ACTION_LEVEL='info'
}

xmj_font_notice_color() {
  case "${XMJ_FONT_ACTION_LEVEL:-info}" in
    success)
      printf '%s' "$XMJ_CREAM"
      ;;
    warn)
      printf '%s' "$XMJ_WARN"
      ;;
    *)
      printf '%s' "$XMJ_MIST"
      ;;
  esac
}
