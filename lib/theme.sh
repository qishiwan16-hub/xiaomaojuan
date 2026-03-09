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

xmj_rule_line() {
  local color="${1:-$XMJ_BORDER}"
  local char="${2:-─}"
  local count="${3:-62}"
  local motif='(=^･ω･^=)'
  local pad_char='~'
  local inner_width=0
  local left_count=0
  local right_count=0
  local left_pad=''
  local right_pad=''

  case "$char" in
    '═')
      pad_char='='
      ;;
    *)
      pad_char='~'
      ;;
  esac

  inner_width=$((count - ${#motif} - 2))
  if [ "$inner_width" -lt 0 ]; then
    inner_width=0
  fi

  left_count=$((inner_width / 2))
  right_count=$((inner_width - left_count))
  left_pad="$(xmj_repeat_char "$pad_char" "$left_count")"
  right_pad="$(xmj_repeat_char "$pad_char" "$right_count")"

  printf '%b%s %s %s%b\n' "$color" "$left_pad" "$motif" "$right_pad" "$XMJ_RESET"
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
