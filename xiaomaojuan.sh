#!/data/data/com.termux/files/usr/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/theme.sh
source "$SCRIPT_DIR/lib/theme.sh"
# shellcheck source=lib/menu_data.sh
source "$SCRIPT_DIR/lib/menu_data.sh"
# shellcheck source=lib/render.sh
source "$SCRIPT_DIR/lib/render.sh"
# shellcheck source=lib/router.sh
source "$SCRIPT_DIR/lib/router.sh"

main() {
  xmj_init_theme
  xmj_run_panel
}

main "$@"
