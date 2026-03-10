#!/data/data/com.termux/files/usr/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XMJ_ROOT_DIR="$SCRIPT_DIR"

# shellcheck source=lib/config.sh
source "$XMJ_ROOT_DIR/lib/config.sh"
# shellcheck source=lib/theme.sh
source "$XMJ_ROOT_DIR/lib/theme.sh"
# shellcheck source=lib/font.sh
source "$XMJ_ROOT_DIR/lib/font.sh"
# shellcheck source=lib/menu_data.sh
source "$XMJ_ROOT_DIR/lib/menu_data.sh"
# shellcheck source=lib/render.sh
source "$XMJ_ROOT_DIR/lib/render.sh"
# shellcheck source=lib/maintenance.sh
source "$XMJ_ROOT_DIR/lib/maintenance.sh"
# shellcheck source=lib/update.sh
source "$XMJ_ROOT_DIR/lib/update.sh"
# shellcheck source=lib/version_switch.sh
source "$XMJ_ROOT_DIR/lib/version_switch.sh"
# shellcheck source=lib/launch.sh
source "$XMJ_ROOT_DIR/lib/launch.sh"
# shellcheck source=lib/maintenance_override.sh
source "$XMJ_ROOT_DIR/lib/maintenance_override.sh"
# shellcheck source=lib/extend.sh
source "$XMJ_ROOT_DIR/lib/extend.sh"
# shellcheck source=lib/router.sh
source "$XMJ_ROOT_DIR/lib/router.sh"

main() {
  local launch_mode="${1:-panel}"

  xmj_bootstrap_config || true
  xmj_init_theme
  xmj_init_font_state

  if [ "${XMJ_CONFIG_READY:-0}" != '1' ]; then
    case "$launch_mode" in
      --autostart-launch)
        return 1
        ;;
      *)
        xmj_render_startup_failure
        ;;
    esac
    return 1
  fi

  case "$launch_mode" in
    --autostart-launch)
      xmj_run_tavern_launch_headless
      ;;
    *)
      xmj_run_panel
      ;;
  esac
}

main "$@"
