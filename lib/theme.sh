xmj_init_theme() {
  XMJ_RESET=$'\033[0m'
  XMJ_BOLD=$'\033[1m'
  XMJ_DIM=$'\033[2m'

  case "${XMJ_THEME_MODE:-pastel}" in
    moonlight)
      XMJ_PINK=$'\033[38;5;183m'
      XMJ_PINK_SOFT=$'\033[38;5;189m'
      XMJ_BLUE=$'\033[38;5;111m'
      XMJ_BLUE_SOFT=$'\033[38;5;153m'
      XMJ_WHITE=$'\033[97m'
      XMJ_CREAM=$'\033[38;5;225m'
      XMJ_LAVENDER=$'\033[38;5;147m'
      XMJ_BORDER=$'\033[38;5;111m'
      XMJ_MIST=$'\033[38;5;250m'
      XMJ_WARN=$'\033[38;5;217m'
      ;;
    *)
      XMJ_PINK=$'\033[38;5;218m'
      XMJ_PINK_SOFT=$'\033[38;5;225m'
      XMJ_BLUE=$'\033[38;5;153m'
      XMJ_BLUE_SOFT=$'\033[38;5;159m'
      XMJ_WHITE=$'\033[97m'
      XMJ_CREAM=$'\033[38;5;224m'
      XMJ_LAVENDER=$'\033[38;5;183m'
      XMJ_BORDER=$'\033[38;5;189m'
      XMJ_MIST=$'\033[38;5;252m'
      XMJ_WARN=$'\033[38;5;217m'
      ;;
  esac
}

xmj_clear_screen() {
  printf '\033[3J\033[2J\033[H'
}

xmj_terminal_width() {
  local width="${COLUMNS:-}"

  case "$width" in
    ''|*[!0-9]*)
      width=''
      ;;
  esac

  if [ -z "$width" ] && command -v tput >/dev/null 2>&1; then
    width="$(tput cols 2>/dev/null || true)"
    case "$width" in
      ''|*[!0-9]*)
        width=''
        ;;
    esac
  fi

  if [ -z "$width" ] || [ "$width" -lt 28 ]; then
    width=62
  fi

  printf '%s' "$width"
}

xmj_panel_width() {
  local width

  width="$(xmj_terminal_width)"
  width=$((width - 4))

  if [ "$width" -lt 24 ]; then
    width=24
  fi

  printf '%s' "$width"
}

xmj_repeat_char() {
  local char="${1:-─}"
  local count="${2:-62}"
  local output=""
  local i

  for ((i = 0; i < count; i++)); do
    output+="$char"
  done

  printf '%s' "$output"
}

xmj_repeat_pattern() {
  local pattern="${1:-°. ⑅♡⑅.°. +.}"
  local count="${2:-62}"
  local output=''

  if [ "$count" -le 0 ]; then
    printf '%s' ''
    return 0
  fi

  while [ "${#output}" -lt "$count" ]; do
    output+="$pattern"
  done

  printf '%s' "${output:0:$count}"
}

xmj_rule_line() {
  local color="${1:-$XMJ_BORDER}"
  local char="${2:-─}"
  local count="${3:-62}"
  local panel_width
  local pattern='°. ⑅♡⑅.°. +.'

  panel_width="$(xmj_panel_width)"
  if [ "$panel_width" -gt 6 ]; then
    panel_width=$((panel_width - 2))
  fi

  case "$count" in
    ''|*[!0-9]*)
      count="$panel_width"
      ;;
  esac

  if [ "$count" -le 0 ] || [ "$count" -gt "$panel_width" ]; then
    count="$panel_width"
  fi

  case "$char" in
    '═')
      pattern='°. ⑅♡⑅.°. +.'
      ;;
    *)
      pattern='°. ⑅♡⑅.°.'
      ;;
  esac

  printf '%b%s%b\n' "$color" "$(xmj_repeat_pattern "$pattern" "$count")" "$XMJ_RESET"
}

xmj_wait_for_enter() {
  local prompt="${1:-按回车返回首页}"

  printf '%b' "${XMJ_BLUE_SOFT}${prompt}${XMJ_RESET}"
  IFS= read -r _
}

xmj_paint() {
  local color="${1:-$XMJ_WHITE}"
  shift || true
  printf '%b%s%b' "$color" "$*" "$XMJ_RESET"
}
