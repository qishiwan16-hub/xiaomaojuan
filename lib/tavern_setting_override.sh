xmj_tavern_setting_is_private_ipv4() {
  local ipv4="${1:-}"
  local a=''
  local b=''
  local c=''
  local d=''
  local octet=''

  if [[ ! "$ipv4" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi

  IFS='.' read -r a b c d <<EOF
$ipv4
EOF

  for octet in "$a" "$b" "$c" "$d"; do
    if ! [[ "$octet" =~ ^[0-9]+$ ]] || [ "$octet" -gt 255 ]; then
      return 1
    fi
  done

  if [ "$a" = '10' ]; then
    return 0
  fi

  if [ "$a" = '192' ] && [ "$b" = '168' ]; then
    return 0
  fi

  if [ "$a" = '172' ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]; then
    return 0
  fi

  return 1
}

xmj_tavern_setting_auto_lan_ip() {
  local line=''
  local lan_ip=''

  if command -v ip >/dev/null 2>&1; then
    line="$(ip route get 1.1.1.1 2>/dev/null | head -n 1)"
    if [[ "$line" =~ [[:space:]]src[[:space:]]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
      lan_ip="${BASH_REMATCH[1]}"
      if xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
        printf '%s' "$lan_ip"
        return 0
      fi
    fi

    while IFS= read -r line; do
      if [[ "$line" =~ inet[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\/ ]]; then
        lan_ip="${BASH_REMATCH[1]}"
        if xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
          printf '%s' "$lan_ip"
          return 0
        fi
      fi
    done < <(ip -4 -o addr show up scope global 2>/dev/null)
  fi

  if command -v ifconfig >/dev/null 2>&1; then
    while IFS= read -r line; do
      if [[ "$line" =~ inet[[:space:]](addr:)?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
        lan_ip="${BASH_REMATCH[2]}"
        if xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
          printf '%s' "$lan_ip"
          return 0
        fi
      fi
    done < <(ifconfig 2>/dev/null)
  fi

  printf '%s' ''
}

xmj_tavern_setting_host_whitelist_lan_host() {
  local config_file="${1:-}"
  local section_text=''
  local line=''
  local host=''

  if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
    printf '%s' ''
    return 0
  fi

  section_text="$(xmj_tavern_setting_yaml_section_text "$config_file" 'hostWhitelist')"
  if [ -z "$section_text" ]; then
    printf '%s' ''
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"?([^\"#[:space:]]+)\"?[[:space:]]*($|#) ]]; then
      host="${BASH_REMATCH[1]}"
      if [ "$host" = 'localhost' ] || [ "$host" = '127.0.0.1' ] || [ "$host" = '[::1]' ]; then
        continue
      fi
      if xmj_tavern_setting_is_private_ipv4 "$host"; then
        printf '%s' "$host"
        return 0
      fi
    fi
  done <<EOF
$section_text
EOF

  printf '%s' ''
}

xmj_tavern_setting_host_whitelist_has_host() {
  local config_file="${1:-}"
  local target_host="${2:-}"
  local section_text=''
  local line=''
  local host=''

  if [ -z "$config_file" ] || [ ! -f "$config_file" ] || [ -z "$target_host" ]; then
    return 1
  fi

  section_text="$(xmj_tavern_setting_yaml_section_text "$config_file" 'hostWhitelist')"
  if [ -z "$section_text" ]; then
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"?([^\"#[:space:]]+)\"?[[:space:]]*($|#) ]]; then
      host="${BASH_REMATCH[1]}"
      if [ "$host" = "$target_host" ]; then
        return 0
      fi
    fi
  done <<EOF
$section_text
EOF

  return 1
}

xmj_tavern_setting_host_whitelist_lan_block() {
  local lan_ip="${1:-}"

  cat <<EOF
hostWhitelist:
  enabled: true
  scan: true
  hosts:
    - localhost
    - 127.0.0.1
    - "[::1]"
    - ${lan_ip}
EOF
}

xmj_tavern_setting_current_port() {
  local config_file=''
  local port_value=''

  config_file="$(xmj_tavern_setting_config_file)"
  port_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'port')"

  if ! [[ "$port_value" =~ ^[0-9]+$ ]] || [ "$port_value" -lt 1 ]; then
    port_value="${XMJ_TAVERN_PORT:-8000}"
  fi

  if ! [[ "$port_value" =~ ^[0-9]+$ ]] || [ "$port_value" -lt 1 ]; then
    port_value='8000'
  fi

  printf '%s' "$port_value"
}

xmj_tavern_setting_selected_lan_ip() {
  local auto_ip=''
  local config_ip=''

  if xmj_tavern_setting_is_private_ipv4 "${XMJ_TAVERN_SETTING_LAN_IP:-}"; then
    printf '%s' "${XMJ_TAVERN_SETTING_LAN_IP:-}"
    return 0
  fi

  auto_ip="$(xmj_tavern_setting_auto_lan_ip)"
  if xmj_tavern_setting_is_private_ipv4 "$auto_ip"; then
    printf '%s' "$auto_ip"
    return 0
  fi

  config_ip="$(xmj_tavern_setting_host_whitelist_lan_host "$(xmj_tavern_setting_config_file)")"
  if xmj_tavern_setting_is_private_ipv4 "$config_ip"; then
    printf '%s' "$config_ip"
    return 0
  fi

  printf '%s' ''
}

xmj_tavern_setting_lan_url() {
  local lan_ip="${1:-}"
  local port_value=''

  if [ -z "$lan_ip" ]; then
    lan_ip="$(xmj_tavern_setting_selected_lan_ip)"
  fi

  if [ -z "$lan_ip" ]; then
    printf '%s' ''
    return 0
  fi

  port_value="$(xmj_tavern_setting_current_port)"
  printf 'http://%s:%s/' "$lan_ip" "$port_value"
}

xmj_tavern_setting_lan_link_status_text() {
  local config_file=''
  local written_ip=''
  local listen_value=''
  local selected_ip=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到酒馆配置文件'
    return 0
  fi

  written_ip="$(xmj_tavern_setting_host_whitelist_lan_host "$config_file")"
  listen_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'listen')"

  if [ -n "$written_ip" ] && [ "$listen_value" = 'true' ] && xmj_tavern_setting_host_whitelist_has_host "$config_file" "$written_ip"; then
    printf '当前：%s' "$(xmj_tavern_setting_lan_url "$written_ip")"
    return 0
  fi

  if [ -n "$written_ip" ] && [ "$listen_value" != 'true' ]; then
    printf '当前：白名单里有 %s，但 listen 还没开' "$written_ip"
    return 0
  fi

  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"
  if [ -n "$selected_ip" ]; then
    printf '当前：待写入 %s' "$(xmj_tavern_setting_lan_url "$selected_ip")"
    return 0
  fi

  printf '%s' '当前：没识别到局域网 IPv4'
}

xmj_tavern_setting_security_guard_status_text() {
  local config_file=''
  local current_version=''
  local compat_floor=''
  local lan_ip=''
  local listen_value=''

  config_file="$(xmj_tavern_setting_config_file)"
  current_version="$(xmj_tavern_setting_current_version)"
  compat_floor="$(xmj_maintenance_compat_floor_version)"

  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到酒馆配置文件'
    return 0
  fi

  if [ -z "$(xmj_maintenance_extract_semver "$current_version")" ]; then
    printf '当前：版本未识别（%s）' "${current_version:-未读到}"
    return 0
  fi

  if xmj_maintenance_version_lt "$current_version" "$compat_floor"; then
    printf '当前：%s 低于 %s' "$current_version" "$compat_floor"
    return 0
  fi

  if xmj_tavern_setting_host_whitelist_is_local_only "$config_file"; then
    printf '%s' '当前：已限制为本机访问'
    return 0
  fi

  lan_ip="$(xmj_tavern_setting_host_whitelist_lan_host "$config_file")"
  listen_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'listen')"
  if [ -n "$lan_ip" ] && [ "$listen_value" = 'true' ]; then
    printf '当前：正在走局域网白名单（%s）' "$lan_ip"
    return 0
  fi

  if [ -n "$lan_ip" ]; then
    printf '当前：白名单里还有局域网 IP（%s）' "$lan_ip"
    return 0
  fi

  printf '%s' '当前：还没套用本机防护'
}

xmj_tavern_setting_apply_lan_link_fix() {
  local config_file=''
  local lan_ip=''
  local block_text=''
  local lan_url=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  lan_ip="$(xmj_tavern_setting_selected_lan_ip)"
  if ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    xmj_font_set_notice 'warn' '没识别到可用的局域网 IPv4，先去手动填写一个 192.168.x.x / 10.x.x.x / 172.16-31.x.x 地址。'
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'listen' 'true'; then
    xmj_font_set_notice 'warn' "listen 没写进去：$(xmj_display_path "$config_file")"
    return 1
  fi

  block_text="$(xmj_tavern_setting_host_whitelist_lan_block "$lan_ip")"
  if ! xmj_tavern_setting_replace_yaml_section_block "$config_file" 'hostWhitelist' "$block_text"; then
    xmj_font_set_notice 'warn' "局域网白名单没写进去：$(xmj_display_path "$config_file")"
    return 1
  fi

  XMJ_TAVERN_SETTING_LAN_IP="$lan_ip"
  lan_url="$(xmj_tavern_setting_lan_url "$lan_ip")"
  xmj_font_set_notice 'success' "已把 listen 改成 true，并把 hostWhitelist 写成 localhost / 127.0.0.1 / [::1] / ${lan_ip}；同一局域网直接访问 ${lan_url}，重开酒馆后生效。"
  return 0
}

xmj_tavern_setting_update_lan_link_ip() {
  local lan_ip=''

  lan_ip="$(xmj_tavern_setting_trim_spaces "${1:-}")"
  if ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    xmj_font_set_notice 'warn' '这里只支持输入局域网 IPv4，例如 192.168.x.x / 10.x.x.x / 172.16-31.x.x。'
    return 1
  fi

  XMJ_TAVERN_SETTING_LAN_IP="$lan_ip"
  xmj_font_set_notice 'success' "已记住这次要写入的局域网 IP：${lan_ip}。"
  return 0
}

xmj_tavern_setting_reset_lan_link_ip() {
  XMJ_TAVERN_SETTING_LAN_IP=''
  xmj_font_set_notice 'success' '已清掉手动填写的局域网 IP，回到自动识别。'
  return 0
}

xmj_tavern_setting_view_title() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      printf '%s' '浏览器跳转'
      ;;
    avatar_hd)
      printf '%s' '头像高清'
      ;;
    stutter_fix)
      printf '%s' '卡顿修复'
      ;;
    file_chat_limit)
      printf '%s' '文件聊天上限修改'
      ;;
    memory_limit)
      printf '%s' '运行内存修改'
      ;;
    port_conflict)
      printf '%s' '修复端口冲突'
      ;;
    security_guard)
      printf '%s' '安全修复'
      ;;
    multi_user_login)
      printf '%s' '多用户登录'
      ;;
    chat_freeze_fix)
      printf '%s' '聊天加载卡死修复'
      ;;
    beautify_freeze_fix)
      printf '%s' '美化卡死修复'
      ;;
    backup_keep_count)
      printf '%s' '修改备份数量'
      ;;
    user_folder|stutter_fix_user)
      printf '%s' '默认文件夹设置'
      ;;
    lan_link)
      printf '%s' '局域网链接'
      ;;
    lan_link_ip)
      printf '%s' '修改局域网 IP'
      ;;
    *)
      printf '%s' "${XMJ_MENU_LABEL['20']}"
      ;;
  esac
}

xmj_tavern_setting_view_id() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      printf '%s' '20-1'
      ;;
    avatar_hd)
      printf '%s' '20-2'
      ;;
    stutter_fix)
      printf '%s' '20-3'
      ;;
    file_chat_limit)
      printf '%s' '20-4'
      ;;
    memory_limit)
      printf '%s' '20-5'
      ;;
    port_conflict)
      printf '%s' '20-6'
      ;;
    chat_freeze_fix)
      printf '%s' '20-7'
      ;;
    beautify_freeze_fix)
      printf '%s' '20-8'
      ;;
    backup_keep_count)
      printf '%s' '20-9'
      ;;
    user_folder|stutter_fix_user)
      printf '%s' '20-13'
      ;;
    security_guard)
      printf '%s' '20-10'
      ;;
    multi_user_login)
      printf '%s' '20-11'
      ;;
    lan_link)
      printf '%s' '20-12'
      ;;
    lan_link_ip)
      printf '%s' '20-12-IP'
      ;;
    *)
      printf '%s' '20'
      ;;
  esac
}

xmj_tavern_setting_status_text() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      xmj_tavern_setting_browser_redirect_status_text
      ;;
    avatar_hd)
      xmj_tavern_setting_avatar_hd_status_text
      ;;
    stutter_fix)
      xmj_tavern_setting_stutter_fix_status_text
      ;;
    file_chat_limit)
      xmj_tavern_setting_file_chat_limit_status_text
      ;;
    memory_limit)
      xmj_tavern_setting_memory_limit_status_text
      ;;
    port_conflict)
      xmj_tavern_setting_port_conflict_status_text
      ;;
    security_guard)
      xmj_tavern_setting_security_guard_status_text
      ;;
    multi_user_login)
      xmj_tavern_setting_multi_user_login_status_text
      ;;
    chat_freeze_fix)
      xmj_tavern_setting_chat_freeze_fix_status_text
      ;;
    beautify_freeze_fix)
      xmj_tavern_setting_beautify_freeze_fix_status_text
      ;;
    backup_keep_count)
      printf '当前：保留最新 %s 个' "$(xmj_backup_cleanup_keep_count)"
      ;;
    user_folder|stutter_fix_user)
      xmj_tavern_setting_user_folder_status_text
      ;;
    lan_link|lan_link_ip)
      xmj_tavern_setting_lan_link_status_text
      ;;
    *)
      printf '%s' '当前：等你继续给规则'
      ;;
  esac
}

xmj_render_tavern_setting_page() {
  local view="${1:-home}"

  case "$view" in
    browser_redirect)
      xmj_render_tavern_setting_browser_redirect_page
      ;;
    avatar_hd)
      xmj_render_tavern_setting_avatar_hd_page
      ;;
    stutter_fix)
      xmj_render_tavern_setting_stutter_fix_page
      ;;
    file_chat_limit)
      xmj_render_tavern_setting_file_chat_limit_page
      ;;
    memory_limit)
      xmj_render_tavern_setting_memory_limit_page
      ;;
    port_conflict)
      xmj_render_tavern_setting_port_conflict_page
      ;;
    security_guard)
      xmj_render_tavern_setting_security_guard_page
      ;;
    multi_user_login)
      xmj_render_tavern_setting_multi_user_login_page
      ;;
    chat_freeze_fix)
      xmj_render_tavern_setting_chat_freeze_fix_page
      ;;
    beautify_freeze_fix)
      xmj_render_tavern_setting_beautify_freeze_fix_page
      ;;
    backup_keep_count)
      xmj_render_tavern_setting_backup_keep_count_page
      ;;
    user_folder|stutter_fix_user)
      xmj_render_tavern_setting_user_folder_page
      ;;
    lan_link)
      xmj_render_tavern_setting_lan_link_page
      ;;
    lan_link_ip)
      xmj_render_tavern_setting_lan_link_ip_page
      ;;
    *)
      xmj_render_tavern_setting_overview_page
      ;;
  esac
}

xmj_render_tavern_setting_overview_page() {
  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['20']}" 'tavern setting' 'setting'
  printf '\n'
  printf '  %b酒馆设置现在一共收进 13 项，网络访问相关的内容已经拆成“安全修复”和“局域网链接”两条。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b只想本机玩就走 10 安全修复；想让同一局域网里的手机、平板或电脑连进来，就走 12 局域网链接。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '  %b需要按某个 data 用户文件夹去改 settings.json 的几项，现在统一走 13 默认文件夹设置；设好后会一直保留，不会自动改回 default-user。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '\n'
  xmj_render_setting_card '1 · 浏览器跳转' '' "$(xmj_tavern_setting_status_text 'browser_redirect')"
  printf '\n'
  xmj_render_setting_card '2 · 头像高清' '' "$(xmj_tavern_setting_status_text 'avatar_hd')"
  printf '\n'
  xmj_render_setting_card '3 · 卡顿修复' '' "$(xmj_tavern_setting_status_text 'stutter_fix')"
  printf '\n'
  xmj_render_setting_card '4 · 文件聊天上限修改' '' "$(xmj_tavern_setting_status_text 'file_chat_limit')"
  printf '\n'
  xmj_render_setting_card '5 · 运行内存修改' '' "$(xmj_tavern_setting_status_text 'memory_limit')"
  printf '\n'
  xmj_render_setting_card '6 · 修复端口冲突' '' "$(xmj_tavern_setting_status_text 'port_conflict')"
  printf '\n'
  xmj_render_setting_card '7 · 聊天加载卡死修复' '' "$(xmj_tavern_setting_status_text 'chat_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '8 · 美化卡死修复' '' "$(xmj_tavern_setting_status_text 'beautify_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '9 · 修改备份数量' '' "$(xmj_tavern_setting_status_text 'backup_keep_count')"
  printf '\n'
  xmj_render_setting_card '10 · 安全修复' '' "$(xmj_tavern_setting_status_text 'security_guard')"
  printf '\n'
  xmj_render_setting_card '11 · 多用户登录' '' "$(xmj_tavern_setting_status_text 'multi_user_login')"
  printf '\n'
  xmj_render_setting_card '12 · 局域网链接' '' "$(xmj_tavern_setting_status_text 'lan_link')"
  printf '\n'
  xmj_render_setting_card '13 · 默认文件夹设置' '' "$(xmj_tavern_setting_status_text 'user_folder')"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '浏览器跳转'
  xmj_render_action_item '2' '头像高清'
  xmj_render_action_item '3' '卡顿修复'
  xmj_render_action_item '4' '文件聊天上限修改'
  xmj_render_action_item '5' '运行内存修改'
  xmj_render_action_item '6' '修复端口冲突'
  xmj_render_action_item '7' '聊天加载卡死修复'
  xmj_render_action_item '8' '美化卡死修复'
  xmj_render_action_item '9' '修改备份数量'
  xmj_render_action_item '10' '安全修复'
  xmj_render_action_item '11' '多用户登录'
  xmj_render_action_item '12' '局域网链接'
  xmj_render_action_item '13' '默认文件夹设置'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 / 11 / 12 / 13 / 0 就好啦'
}

xmj_render_tavern_setting_security_guard_page() {
  local config_file=''
  local current_version=''
  local compat_floor=''

  config_file="$(xmj_tavern_setting_config_file)"
  current_version="$(xmj_tavern_setting_current_version)"
  compat_floor="$(xmj_maintenance_compat_floor_version)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'security_guard')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会把 hostWhitelist 改成只允许本机访问' \
    "主要面向 ${compat_floor} 及以上版本；猫猫会把 hostWhitelist 写成 enabled: true、scan: true，并只保留 localhost / 127.0.0.1 / [::1]。" \
    '如果你平时只在本机或本机浏览器里玩，这样更稳；如果你要给同一局域网里的手机、平板或电脑访问，请改走 12 局域网链接。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'security_guard')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'security_guard')"
  xmj_render_fact_line '当前版本' "${current_version:-未读到}"
  xmj_render_fact_line '建议版本' "${compat_floor} 及以上"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_lan_link_page() {
  local config_file=''
  local auto_ip=''
  local written_ip=''
  local selected_ip=''
  local current_port=''
  local lan_url=''

  config_file="$(xmj_tavern_setting_config_file)"
  auto_ip="$(xmj_tavern_setting_auto_lan_ip)"
  written_ip="$(xmj_tavern_setting_host_whitelist_lan_host "$config_file")"
  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"
  current_port="$(xmj_tavern_setting_current_port)"
  lan_url="$(xmj_tavern_setting_lan_url "$selected_ip")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'lan_link')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会把酒馆改成同一局域网可访问' \
    '猫猫会把 config.yaml 顶层的 listen 改成 true，再把 hostWhitelist 写成 enabled: true、scan: true，并保留 localhost / 127.0.0.1 / [::1] / 你的局域网 IPv4。' \
    '写完后，同一局域网里的手机、平板或电脑直接访问下面这条链接就行；如果自动识别错了，先去 2 修改局域网 IP。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'lan_link')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'lan_link')"
  xmj_render_fact_line '自动识别 IPv4' "${auto_ip:-未识别到}"
  xmj_render_fact_line '当前准备写入' "${selected_ip:-还没选到}"
  xmj_render_fact_line '已写入白名单' "${written_ip:-还没写}"
  xmj_render_fact_line '当前端口' "$current_port"
  xmj_render_fact_line '局域网链接' "${lan_url:-等你先写入一个局域网 IPv4}"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '写入当前局域网链接'
  xmj_render_action_item '2' '修改局域网 IP'
  xmj_render_action_item '8' '改回自动识别'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 直接写入 / 2 修改局域网 IP / 8 改回自动识别 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_lan_link_ip_page() {
  local auto_ip=''
  local written_ip=''
  local selected_ip=''

  auto_ip="$(xmj_tavern_setting_auto_lan_ip)"
  written_ip="$(xmj_tavern_setting_host_whitelist_lan_host "$(xmj_tavern_setting_config_file)")"
  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'lan_link_ip')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里填的是要写进 hostWhitelist 的局域网 IPv4' \
    '建议填你当前设备在局域网里的私有地址，例如 192.168.x.x / 10.x.x.x / 172.16-31.x.x；不要直接填公网地址，也不用带端口。' \
    '填完后会先记在这次会话里，回到上一页再执行写入；如果你想恢复自动识别，直接按 8。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'lan_link_ip')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'lan_link_ip')"
  xmj_render_fact_line '自动识别 IPv4' "${auto_ip:-未识别到}"
  xmj_render_fact_line '当前准备写入' "${selected_ip:-还没选到}"
  xmj_render_fact_line '已写入白名单' "${written_ip:-还没写}"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '直接输入 IPv4' '输入后会保存并返回上一页'
  xmj_render_action_item '8' '清掉手动 IP，改回自动识别'
  xmj_render_action_item '0' '返回局域网链接'
  xmj_render_action_footer '直接输入 IPv4 / 8 改回自动识别 / 0 返回局域网链接'
}

xmj_handle_tavern_setting_action() {
  local view="${1:-home}"
  local input="${2:-}"

  XMJ_TAVERN_SETTING_NEXT_VIEW="$view"

  case "$view" in
    home)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='exit'
          ;;
        1)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='browser_redirect'
          ;;
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='avatar_hd'
          ;;
        3)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix'
          ;;
        4)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='file_chat_limit'
          ;;
        5)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='memory_limit'
          ;;
        6)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='port_conflict'
          ;;
        7)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='chat_freeze_fix'
          ;;
        8)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='beautify_freeze_fix'
          ;;
        9)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='backup_keep_count'
          ;;
        10)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='security_guard'
          ;;
        11)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='multi_user_login'
          ;;
        12)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='lan_link'
          ;;
        13)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='user_folder'
          ;;
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 / 11 / 12 / 13 / 0。'
          ;;
      esac
      ;;
    browser_redirect)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_browser_redirect_value 'true'
          ;;
        2)
          xmj_tavern_setting_apply_browser_redirect_value 'false'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 0。'
          ;;
      esac
      ;;
    avatar_hd)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_avatar_hd_fix
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。'
          ;;
      esac
      ;;
    stutter_fix)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_stutter_fix
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。默认文件夹请去 13 设置。'
          ;;
      esac
      ;;
    stutter_fix_user|user_folder)
      case "$input" in
        0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        '')
          xmj_font_set_notice 'warn' '默认文件夹不能为空。'
          ;;
        *)
          if xmj_tavern_setting_update_stutter_user "$input"; then
            XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          fi
          ;;
      esac
      ;;
    backup_keep_count)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '这里只支持输入正整数或 0。'
          ;;
        *)
          xmj_tavern_setting_update_backup_keep_count "$input"
          ;;
      esac
      ;;
    file_chat_limit)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '这里直接输入新的上限数字就行，或者输入 0 返回酒馆设置。'
          ;;
        *)
          xmj_tavern_setting_update_file_chat_limit "$input"
          ;;
      esac
      ;;
    memory_limit)
      case "$input" in
        '')
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '这里直接输入 MB 数值；输入 0 恢复默认，回车返回酒馆设置。'
          ;;
        *)
          xmj_tavern_setting_update_memory_limit "$input"
          ;;
      esac
      ;;
    port_conflict)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        *[!0-9]*)
          xmj_font_set_notice 'warn' '这里直接输入新的端口数字就行，或者输入 0 返回酒馆设置。'
          ;;
        *)
          xmj_tavern_setting_update_port_conflict "$input"
          ;;
      esac
      ;;
    security_guard)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_security_guard_fix
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。'
          ;;
      esac
      ;;
    multi_user_login)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_multi_user_login_mode 'avatar_list'
          ;;
        2)
          xmj_tavern_setting_apply_multi_user_login_mode 'discreet_password'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 0。'
          ;;
      esac
      ;;
    chat_freeze_fix|beautify_freeze_fix)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          if [ "$view" = 'chat_freeze_fix' ]; then
            xmj_tavern_setting_apply_chat_freeze_fix
          else
            xmj_tavern_setting_apply_beautify_freeze_fix
          fi
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 0。默认文件夹请去 13 设置。'
          ;;
      esac
      ;;
    lan_link)
      case "$input" in
        ''|0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='home'
          ;;
        1)
          xmj_tavern_setting_apply_lan_link_fix
          ;;
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='lan_link_ip'
          ;;
        8)
          xmj_tavern_setting_reset_lan_link_ip
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 8 / 0。'
          ;;
      esac
      ;;
    lan_link_ip)
      case "$input" in
        0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW='lan_link'
          ;;
        8)
          xmj_tavern_setting_reset_lan_link_ip
          XMJ_TAVERN_SETTING_NEXT_VIEW='lan_link'
          ;;
        '')
          xmj_font_set_notice 'warn' '这里直接输入局域网 IPv4，或者输入 8 改回自动识别。'
          ;;
        *)
          if xmj_tavern_setting_update_lan_link_ip "$input"; then
            XMJ_TAVERN_SETTING_NEXT_VIEW='lan_link'
          fi
          ;;
      esac
      ;;
    *)
      xmj_font_clear_notice
      XMJ_TAVERN_SETTING_NEXT_VIEW='home'
      ;;
  esac

  return 0
}

XMJ_TAVERN_SETTING_LAST_BACKUP_DIR=''
XMJ_TAVERN_SETTING_LAST_BACKUP_ITEMS=''

xmj_tavern_setting_backup_root() {
  local backup_root=''

  backup_root="${XMJ_BACKUP_DIR:-}"
  if [ -z "$backup_root" ] && declare -F xmj_maintenance_backup_dir >/dev/null 2>&1; then
    backup_root="$(xmj_maintenance_backup_dir)"
  fi
  if [ -z "$backup_root" ]; then
    backup_root="${XMJ_ROOT_DIR:-.}/backups"
  fi

  printf '%s/tavern-setting-files' "$backup_root"
}

xmj_tavern_setting_backup_slug() {
  local text="${1:-backup}"

  text="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]' | sed \
    -e 's/[^[:alnum:]._-]/-/g' \
    -e 's/--*/-/g' \
    -e 's/^-//' \
    -e 's/-$//')"

  if [ -z "$text" ]; then
    text='backup'
  fi

  printf '%s' "$text"
}

xmj_tavern_setting_backup_reset_result() {
  XMJ_TAVERN_SETTING_LAST_BACKUP_DIR=''
  XMJ_TAVERN_SETTING_LAST_BACKUP_ITEMS=''
}

xmj_tavern_setting_backup_targets() {
  local op_name="${1:-setting}"
  local backup_root=''
  local backup_dir=''
  local stamp=''
  local file_path=''
  local target_file=''
  local copied='0'
  local copied_items=''
  local index='0'
  shift

  xmj_tavern_setting_backup_reset_result

  backup_root="$(xmj_tavern_setting_backup_root)"
  if ! mkdir -p "$backup_root" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法创建酒馆设置备份目录：$(xmj_display_path "$backup_root")"
    return 1
  fi

  stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || true)"
  if [ -z "$stamp" ]; then
    stamp='manual'
  fi

  backup_dir="$backup_root/${stamp}-$(xmj_tavern_setting_backup_slug "$op_name")"
  if ! mkdir -p "$backup_dir" 2>/dev/null; then
    xmj_font_set_notice 'warn' "无法创建这次设置备份目录：$(xmj_display_path "$backup_dir")"
    return 1
  fi

  for file_path in "$@"; do
    if [ -z "$file_path" ] || [ ! -e "$file_path" ]; then
      continue
    fi

    index=$((index + 1))
    target_file="$backup_dir/${index}-$(basename "$file_path")"

    if ! cp -p "$file_path" "$target_file" 2>/dev/null; then
      rm -rf "$backup_dir" 2>/dev/null || true
      xmj_font_set_notice 'warn' "备份对应文件失败：$(xmj_display_path "$file_path")"
      return 1
    fi

    copied='1'
    if [ -n "$copied_items" ]; then
      copied_items="${copied_items} / "
    fi
    copied_items="${copied_items}$(basename "$file_path")"
  done

  if [ "$copied" != '1' ]; then
    rm -rf "$backup_dir" 2>/dev/null || true
    return 0
  fi

  XMJ_TAVERN_SETTING_LAST_BACKUP_DIR="$backup_dir"
  XMJ_TAVERN_SETTING_LAST_BACKUP_ITEMS="$copied_items"
  return 0
}

xmj_tavern_setting_backup_note_text() {
  if [ -z "${XMJ_TAVERN_SETTING_LAST_BACKUP_DIR:-}" ]; then
    printf '%s' ''
    return 0
  fi

  printf '已先备份 %s 到 %s。' \
    "${XMJ_TAVERN_SETTING_LAST_BACKUP_ITEMS:-对应文件}" \
    "$(xmj_display_path "${XMJ_TAVERN_SETTING_LAST_BACKUP_DIR}")"
}

xmj_tavern_setting_append_backup_note() {
  local base_text="${1:-}"
  local backup_text=''

  backup_text="$(xmj_tavern_setting_backup_note_text)"
  if [ -z "$backup_text" ]; then
    printf '%s' "$base_text"
    return 0
  fi

  if [ -n "$base_text" ]; then
    printf '%s %s' "$base_text" "$backup_text"
    return 0
  fi

  printf '%s' "$backup_text"
}

xmj_render_tavern_setting_overview_page() {
  local backup_root=''

  backup_root="$(xmj_tavern_setting_backup_root)"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "${XMJ_MENU_LABEL['20']}" 'tavern setting' 'setting'
  printf '\n'
  printf '  %b酒馆设置现在一共收进 12 项，网络访问相关的内容已经拆成“安全修复”和“局域网链接”两条。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b只想本机玩就走 10 安全修复；想让同一局域网里的手机、平板或电脑连进来，就走 12 局域网链接。%b\n' "$XMJ_MIST" "$XMJ_RESET"
  printf '  %b所有会改文件的设置都会先把对应文件收进备份目录：%s%b\n' "$XMJ_BLUE_SOFT" "$(xmj_display_path "$backup_root")" "$XMJ_RESET"
  printf '\n'
  xmj_render_setting_card '1 · 浏览器跳转' '' "$(xmj_tavern_setting_status_text 'browser_redirect')"
  printf '\n'
  xmj_render_setting_card '2 · 头像高清' '' "$(xmj_tavern_setting_status_text 'avatar_hd')"
  printf '\n'
  xmj_render_setting_card '3 · 卡顿修复' '' "$(xmj_tavern_setting_status_text 'stutter_fix')"
  printf '\n'
  xmj_render_setting_card '4 · 文件聊天上限修改' '' "$(xmj_tavern_setting_status_text 'file_chat_limit')"
  printf '\n'
  xmj_render_setting_card '5 · 运行内存修改' '' "$(xmj_tavern_setting_status_text 'memory_limit')"
  printf '\n'
  xmj_render_setting_card '6 · 修复端口冲突' '' "$(xmj_tavern_setting_status_text 'port_conflict')"
  printf '\n'
  xmj_render_setting_card '7 · 聊天加载卡死修复' '' "$(xmj_tavern_setting_status_text 'chat_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '8 · 美化卡死修复' '' "$(xmj_tavern_setting_status_text 'beautify_freeze_fix')"
  printf '\n'
  xmj_render_setting_card '9 · 修改备份数量' '' "$(xmj_tavern_setting_status_text 'backup_keep_count')"
  printf '\n'
  xmj_render_setting_card '10 · 安全修复' '' "$(xmj_tavern_setting_status_text 'security_guard')"
  printf '\n'
  xmj_render_setting_card '11 · 多用户登录' '' "$(xmj_tavern_setting_status_text 'multi_user_login')"
  printf '\n'
  xmj_render_setting_card '12 · 局域网链接' '' "$(xmj_tavern_setting_status_text 'lan_link')"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '浏览器跳转'
  xmj_render_action_item '2' '头像高清'
  xmj_render_action_item '3' '卡顿修复'
  xmj_render_action_item '4' '文件聊天上限修改'
  xmj_render_action_item '5' '运行内存修改'
  xmj_render_action_item '6' '修复端口冲突'
  xmj_render_action_item '7' '聊天加载卡死修复'
  xmj_render_action_item '8' '美化卡死修复'
  xmj_render_action_item '9' '修改备份数量'
  xmj_render_action_item '10' '安全修复'
  xmj_render_action_item '11' '多用户登录'
  xmj_render_action_item '12' '局域网链接'
  xmj_render_action_item '0' '返回首页'
  xmj_render_action_footer '输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 / 11 / 12 / 0 就好啦'
}

xmj_tavern_setting_apply_browser_redirect_value() {
  local target_value="${1:-false}"
  local config_file=''
  local success_text=''

  case "$target_value" in
    true)
      success_text='已开启浏览器跳转，重开酒馆后会重新按配置自动拉起浏览器。'
      ;;
    *)
      target_value='false'
      success_text='已关闭自动跳浏览器，重开酒馆后生效。'
      ;;
  esac

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'browser-redirect' "$config_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_section_value "$config_file" 'browserLaunch' 'enabled' "$target_value"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "浏览器跳转设置没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "${success_text} $(xmj_display_path "$config_file")")"
  return 0
}

xmj_tavern_setting_apply_avatar_hd_fix() {
  local config_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'avatar-hd' "$config_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_section_value "$config_file" 'thumbnails' 'enabled' 'false'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "头像高清修复没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已关闭缩略头像，重开酒馆后会直接用原图：$(xmj_display_path "$config_file")")"
  return 0
}

xmj_tavern_setting_apply_chat_loading_guard() {
  local mode="${1:-stutter_fix}"
  local config_file=''
  local settings_file=''
  local user_name=''
  local success_text=''

  user_name="$(xmj_tavern_setting_user_name)"
  config_file="$(xmj_tavern_setting_config_file)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if [ ! -f "$settings_file" ]; then
    xmj_font_set_notice 'warn' "没找到这个默认文件夹的 settings.json：$(xmj_display_path "$settings_file")；没开多用户通常就是 default-user。"
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'chat-loading-guard' "$config_file" "$settings_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'lazyLoadCharacters' 'true'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "聊天保护的第 1 步写入失败：$(xmj_display_path "$config_file")")"
    return 1
  fi

  if ! xmj_tavern_setting_set_json_bool_value "$settings_file" 'auto_load_chat' 'false'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "聊天保护的第 2 步写入失败：$(xmj_display_path "$settings_file")")"
    return 1
  fi

  case "$mode" in
    chat_freeze_fix)
      success_text="已关掉自动加载聊天，并打开角色懒加载；当前默认文件夹：${user_name}。"
      ;;
    *)
      success_text="已完成卡顿修复，当前默认文件夹：${user_name}；重开酒馆后再看效果。"
      ;;
  esac

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "$success_text")"
  return 0
}

xmj_tavern_setting_apply_beautify_freeze_fix() {
  local user_name=''
  local settings_file=''
  local theme_value=''
  local custom_css_value=''

  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  if [ ! -f "$settings_file" ]; then
    xmj_font_set_notice 'warn' "没找到这个默认文件夹的 settings.json：$(xmj_display_path "$settings_file")"
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'beautify-freeze-fix' "$settings_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_json_string_value "$settings_file" 'theme' 'Dark Lite'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "安全主题没写进去：$(xmj_display_path "$settings_file")")"
    return 1
  fi

  if ! xmj_tavern_setting_set_json_string_value "$settings_file" 'custom_css' ''; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "custom_css 没清空：$(xmj_display_path "$settings_file")")"
    return 1
  fi

  theme_value="$(xmj_tavern_setting_json_string_value "$settings_file" 'theme')"
  custom_css_value="$(xmj_tavern_setting_json_string_value "$settings_file" 'custom_css')"

  if [ "$theme_value" != 'Dark Lite' ] || [ -n "$custom_css_value" ]; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "美化保护没有完全落稳，先检查：$(xmj_display_path "$settings_file")")"
    return 1
  fi

  xmj_tavern_setting_set_json_string_value "$settings_file" 'customCss' '' >/dev/null 2>&1 || true
  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已切回 Dark Lite 并清空自定义 CSS；当前默认文件夹：${user_name}。")"
  return 0
}

xmj_tavern_setting_update_file_chat_limit() {
  local input_mb="${1:-}"
  local server_main_file=''
  local parser_json_limit=''
  local parser_urlencoded_limit=''
  local parser_updates='0'
  local parser_has_calls='0'
  local parser_can_verify='0'
  local parser_too_low='0'

  case "$input_mb" in
    ''|*[!0-9]*)
      xmj_font_set_notice 'warn' '这里只支持输入正整数上限。'
      return 1
      ;;
  esac

  if [ "$input_mb" -lt 1 ]; then
    xmj_font_set_notice 'warn' '文件聊天上限至少要是 1。'
    return 1
  fi

  server_main_file="$(xmj_tavern_setting_server_main_file)"
  if xmj_tavern_setting_body_parser_has_calls "$server_main_file"; then
    parser_has_calls='1'
  fi
  parser_json_limit="$(xmj_tavern_setting_body_parser_limit_mb "$server_main_file" 'json')"
  parser_urlencoded_limit="$(xmj_tavern_setting_body_parser_limit_mb "$server_main_file" 'urlencoded')"

  if [ "$parser_has_calls" != '1' ]; then
    xmj_font_set_notice 'warn' '没在当前版本里找到可改的 bodyParser / express 上传限制入口。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'file-chat-limit' "$server_main_file"; then
    return 1
  fi

  if [ -n "$parser_json_limit" ]; then
    parser_can_verify='1'
    if [ "$parser_json_limit" -lt "$input_mb" ]; then
      parser_too_low='1'
    fi
  fi

  if [ -n "$parser_urlencoded_limit" ]; then
    parser_can_verify='1'
    if [ "$parser_urlencoded_limit" -lt "$input_mb" ]; then
      parser_too_low='1'
    fi
  fi

  if ! parser_updates="$(xmj_tavern_setting_raise_body_parser_limits_if_needed "$server_main_file" "$input_mb")"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "bodyParser / express 上传限制没改成功：$(xmj_display_path "$server_main_file")")"
    return 1
  fi

  if [ "${parser_updates:-0}" -gt 0 ]; then
    xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把 bodyParser / express 上传限制补到 ${input_mb} MB：$(xmj_display_path "$server_main_file")")"
    return 0
  fi

  if [ "$parser_can_verify" = '1' ] && [ "$parser_too_low" != '1' ]; then
    xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "bodyParser / express 上传限制已经不低于 ${input_mb} MB。")"
    return 0
  fi

  xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "已找到 bodyParser / express 入口，但当前写法不是固定字面量，暂时没法自动确认是否改成功：$(xmj_display_path "$server_main_file")")"
  return 0
}

xmj_tavern_setting_update_memory_limit() {
  local memory_limit_mb="${1:-}"

  case "$memory_limit_mb" in
    ''|*[!0-9]*)
      xmj_font_set_notice 'warn' '这里只支持输入数字，单位是 MB。'
      return 1
      ;;
  esac

  if [ "$memory_limit_mb" -gt 65536 ]; then
    xmj_font_set_notice 'warn' '先别一次把启动内存拉得太离谱；建议从 2048 / 4096 / 6144 / 8192 这几个值开始试。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'memory-limit' "${XMJ_CONFIG_FILE:-}"; then
    return 1
  fi

  if [ "$memory_limit_mb" -eq 0 ]; then
    if ! xmj_config_upsert_value 'XMJ_TAVERN_NODE_MEMORY_MB' '0'; then
      xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "默认启动内存没写回配置：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")")"
      return 1
    fi

    xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note '已恢复默认启动内存；下次 01 启动酒馆时生效。')"
    return 0
  fi

  if [ "$memory_limit_mb" -lt 512 ]; then
    xmj_font_set_notice 'warn' '低于 512 MB 基本帮不上忙；建议至少从 1024 MB 开始，常用值是 2048 / 4096 / 8192。'
    return 1
  fi

  if ! xmj_config_upsert_value 'XMJ_TAVERN_NODE_MEMORY_MB' "$memory_limit_mb"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "运行内存设置没写回配置：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把启动内存改成 ${memory_limit_mb} MB；下次 01 启动酒馆时生效。")"
  return 0
}

xmj_tavern_setting_update_port_conflict() {
  local port_value="${1:-}"
  local config_file=''
  local current_tavern_port=''
  local current_script_port="${XMJ_TAVERN_PORT:-8000}"

  case "$port_value" in
    ''|*[!0-9]*)
      xmj_font_set_notice 'warn' '这里只支持输入 1 到 65535 的端口。'
      return 1
      ;;
  esac

  if [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
    xmj_font_set_notice 'warn' '端口只能在 1 到 65535 之间。'
    return 1
  fi

  if xmj_tavern_setting_port_is_forbidden "$port_value"; then
    xmj_font_set_notice 'warn' '这个端口不在建议范围内；优先用 10000 到 49151 之间的普通端口。'
    return 1
  fi

  if xmj_tavern_setting_port_is_high_risk "$port_value"; then
    xmj_font_set_notice 'warn' '这个端口属于高冲突段，容易和常见服务撞车；换个普通端口更稳。'
    return 1
  fi

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  current_tavern_port="$(xmj_tavern_setting_yaml_top_value "$config_file" 'port')"
  if [ "$current_tavern_port" = "$port_value" ] && [ "$current_script_port" = "$port_value" ]; then
    xmj_font_set_notice 'success' "酒馆和面板现在已经都在走 ${port_value}。"
    return 0
  fi

  if ! xmj_tavern_setting_backup_targets 'port-conflict' "$config_file" "${XMJ_CONFIG_FILE:-}"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'port' "$port_value"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "酒馆端口没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  if ! xmj_config_upsert_value 'XMJ_TAVERN_PORT' "$port_value"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "酒馆 port 已改成 ${port_value}，但小猫卷自己的访问端口没同步写回：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把酒馆 port 和小猫卷访问端口一起改成 ${port_value}；重开酒馆后生效。")"
  return 0
}

xmj_tavern_setting_apply_security_guard_fix() {
  local config_file=''
  local current_version=''
  local compat_floor=''
  local block_text=''

  config_file="$(xmj_tavern_setting_config_file)"
  current_version="$(xmj_tavern_setting_current_version)"
  compat_floor="$(xmj_maintenance_compat_floor_version)"

  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  if [ -z "$(xmj_maintenance_extract_semver "$current_version")" ]; then
    xmj_font_set_notice 'warn' "当前酒馆版本未识别：${current_version:-未读到}；这一项主要面向 ${compat_floor} 及以上版本。"
    return 1
  fi

  if xmj_maintenance_version_lt "$current_version" "$compat_floor"; then
    xmj_font_set_notice 'warn' "当前酒馆版本 ${current_version} 低于 ${compat_floor}；这一项先别直接套。"
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'security-guard' "$config_file"; then
    return 1
  fi

  block_text="$(xmj_tavern_setting_host_whitelist_local_block)"
  if ! xmj_tavern_setting_replace_yaml_section_block "$config_file" 'hostWhitelist' "$block_text"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "安全修复没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note '已把 hostWhitelist 改成仅允许 localhost / 127.0.0.1 / [::1]；局域网或外网访问会被拦住，重开酒馆后生效。')"
  return 0
}

xmj_tavern_setting_apply_multi_user_login_mode() {
  local mode="${1:-avatar_list}"
  local config_file=''
  local discreet_value='false'
  local mode_text='头像列表登录页'

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  case "$mode" in
    discreet_password)
      discreet_value='true'
      mode_text='账号密码登录页'
      ;;
    *)
      mode='avatar_list'
      discreet_value='false'
      mode_text='头像列表登录页'
      ;;
  esac

  if ! xmj_tavern_setting_backup_targets 'multi-user-login' "$config_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'enableUserAccounts' 'true'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "多用户开关没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'enableDiscreetLogin' "$discreet_value"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "登录页模式没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已开启多用户，并切到${mode_text}；重开酒馆后生效。")"
  return 0
}

xmj_tavern_setting_update_backup_keep_count() {
  local keep_count="${1:-}"

  case "$keep_count" in
    ''|*[!0-9]*)
      xmj_font_set_notice 'warn' '这里只支持输入正整数。'
      return 1
      ;;
  esac

  if [ "$keep_count" -lt 1 ]; then
    xmj_font_set_notice 'warn' '备份保留数量至少要是 1。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'backup-keep-count' "${XMJ_CONFIG_FILE:-}"; then
    return 1
  fi

  if ! xmj_config_upsert_value 'XMJ_BACKUP_KEEP_COUNT' "$keep_count"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "写入配置失败：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")")"
    return 1
  fi

  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把自动清理备份保留数量改成 ${keep_count}。")"
  return 0
}

xmj_tavern_setting_apply_lan_link_fix() {
  local config_file=''
  local lan_ip=''
  local block_text=''
  local lan_url=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  lan_ip="$(xmj_tavern_setting_selected_lan_ip)"
  if ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    xmj_font_set_notice 'warn' '没识别到可用的局域网 IPv4，先去手动填写一个 192.168.x.x / 10.x.x.x / 172.16-31.x.x 地址。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'lan-link' "$config_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'listen' 'true'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "listen 没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  block_text="$(xmj_tavern_setting_host_whitelist_lan_block "$lan_ip")"
  if ! xmj_tavern_setting_replace_yaml_section_block "$config_file" 'hostWhitelist' "$block_text"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "局域网白名单没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  XMJ_TAVERN_SETTING_LAN_IP="$lan_ip"
  lan_url="$(xmj_tavern_setting_lan_url "$lan_ip")"
  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把 listen 改成 true，并把 hostWhitelist 写成 localhost / 127.0.0.1 / [::1] / ${lan_ip}；同一局域网直接访问 ${lan_url}，重开酒馆后生效。")"
  return 0
}

xmj_tavern_setting_lan_cidr_from_ip() {
  local lan_ip="${1:-}"
  local a=''
  local b=''

  if ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    printf '%s' ''
    return 0
  fi

  IFS='.' read -r a b _ <<EOF
$lan_ip
EOF

  if [ "$a" = '10' ]; then
    printf '%s' '10.0.0.0/8'
    return 0
  fi

  if [ "$a" = '192' ] && [ "$b" = '168' ]; then
    printf '%s' '192.168.0.0/16'
    return 0
  fi

  if [ "$a" = '172' ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]; then
    printf '%s' '172.16.0.0/12'
    return 0
  fi

  printf '%s' ''
}

xmj_tavern_setting_host_whitelist_lan_entry() {
  local config_file="${1:-}"
  local section_text=''
  local line=''
  local host=''

  if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
    printf '%s' ''
    return 0
  fi

  section_text="$(xmj_tavern_setting_yaml_section_text "$config_file" 'hostWhitelist')"
  if [ -z "$section_text" ]; then
    printf '%s' ''
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"?([^\"#[:space:]]+)\"?[[:space:]]*($|#) ]]; then
      host="${BASH_REMATCH[1]}"
      if [ "$host" = 'localhost' ] || [ "$host" = '127.0.0.1' ] || [ "$host" = '[::1]' ]; then
        continue
      fi
      if xmj_tavern_setting_is_private_ipv4 "$host" || [[ "$host" =~ ^10\.0\.0\.0/8$|^192\.168\.0\.0/16$|^172\.16\.0\.0/12$ ]]; then
        printf '%s' "$host"
        return 0
      fi
    fi
  done <<EOF
$section_text
EOF

  printf '%s' ''
}

xmj_tavern_setting_host_whitelist_lan_host() {
  xmj_tavern_setting_host_whitelist_lan_entry "${1:-}"
}

xmj_tavern_setting_lan_entry_allows_ip() {
  local lan_entry="${1:-}"
  local lan_ip="${2:-}"
  local a=''
  local b=''

  if [ -z "$lan_entry" ] || ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    return 1
  fi

  if [ "$lan_entry" = "$lan_ip" ]; then
    return 0
  fi

  IFS='.' read -r a b _ <<EOF
$lan_ip
EOF

  case "$lan_entry" in
    '10.0.0.0/8')
      [ "$a" = '10' ]
      return $?
      ;;
    '192.168.0.0/16')
      [ "$a" = '192' ] && [ "$b" = '168' ]
      return $?
      ;;
    '172.16.0.0/12')
      [ "$a" = '172' ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]
      return $?
      ;;
  esac

  return 1
}

xmj_tavern_setting_host_whitelist_lan_block() {
  local lan_ip="${1:-}"
  local lan_entry=''

  lan_entry="$(xmj_tavern_setting_lan_cidr_from_ip "$lan_ip")"
  if [ -z "$lan_entry" ]; then
    lan_entry="$lan_ip"
  fi

  cat <<EOF
hostWhitelist:
  enabled: true
  scan: true
  hosts:
    - localhost
    - 127.0.0.1
    - "[::1]"
    - ${lan_entry}
EOF
}

xmj_tavern_setting_lan_link_status_text() {
  local config_file=''
  local written_entry=''
  local listen_value=''
  local selected_ip=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到酒馆配置文件'
    return 0
  fi

  written_entry="$(xmj_tavern_setting_host_whitelist_lan_entry "$config_file")"
  listen_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'listen')"
  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"

  if [ -n "$written_entry" ] && [ "$listen_value" = 'true' ] && xmj_tavern_setting_lan_entry_allows_ip "$written_entry" "$selected_ip"; then
    printf '当前：%s（白名单 %s）' "$(xmj_tavern_setting_lan_url "$selected_ip")" "$written_entry"
    return 0
  fi

  if [ -n "$written_entry" ] && [ "$listen_value" = 'true' ]; then
    printf '当前：listen 已开，白名单 %s' "$written_entry"
    return 0
  fi

  if [ -n "$written_entry" ] && [ "$listen_value" != 'true' ]; then
    printf '当前：白名单里有 %s，但 listen 还没开' "$written_entry"
    return 0
  fi

  if [ -n "$selected_ip" ]; then
    printf '当前：待写入 %s（白名单 %s）' "$(xmj_tavern_setting_lan_url "$selected_ip")" "$(xmj_tavern_setting_lan_cidr_from_ip "$selected_ip")"
    return 0
  fi

  printf '%s' '当前：没识别到局域网 IPv4'
}

xmj_tavern_setting_security_guard_status_text() {
  local config_file=''
  local current_version=''
  local compat_floor=''
  local lan_entry=''
  local listen_value=''

  config_file="$(xmj_tavern_setting_config_file)"
  current_version="$(xmj_tavern_setting_current_version)"
  compat_floor="$(xmj_maintenance_compat_floor_version)"

  if [ -z "$config_file" ]; then
    printf '%s' '当前：没找到酒馆配置文件'
    return 0
  fi

  if [ -z "$(xmj_maintenance_extract_semver "$current_version")" ]; then
    printf '当前：版本未识别（%s）' "${current_version:-未读到}"
    return 0
  fi

  if xmj_maintenance_version_lt "$current_version" "$compat_floor"; then
    printf '当前：%s 低于 %s' "$current_version" "$compat_floor"
    return 0
  fi

  if xmj_tavern_setting_host_whitelist_is_local_only "$config_file"; then
    printf '%s' '当前：已限制为本机访问'
    return 0
  fi

  lan_entry="$(xmj_tavern_setting_host_whitelist_lan_entry "$config_file")"
  listen_value="$(xmj_tavern_setting_yaml_top_value "$config_file" 'listen')"
  if [ -n "$lan_entry" ] && [ "$listen_value" = 'true' ]; then
    printf '当前：正在走局域网白名单（%s）' "$lan_entry"
    return 0
  fi

  if [ -n "$lan_entry" ]; then
    printf '当前：白名单里还有局域网范围（%s）' "$lan_entry"
    return 0
  fi

  printf '%s' '当前：还没套用本机防护'
}

xmj_render_tavern_setting_lan_link_page() {
  local config_file=''
  local auto_ip=''
  local written_entry=''
  local selected_ip=''
  local selected_entry=''
  local current_port=''
  local lan_url=''

  config_file="$(xmj_tavern_setting_config_file)"
  auto_ip="$(xmj_tavern_setting_auto_lan_ip)"
  written_entry="$(xmj_tavern_setting_host_whitelist_lan_entry "$config_file")"
  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"
  selected_entry="$(xmj_tavern_setting_lan_cidr_from_ip "$selected_ip")"
  current_port="$(xmj_tavern_setting_current_port)"
  lan_url="$(xmj_tavern_setting_lan_url "$selected_ip")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'lan_link')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会把酒馆改成同一局域网可访问' \
    '猫猫会把 config.yaml 顶层的 listen 改成 true，再把 hostWhitelist 写成 enabled: true、scan: true，并保留 localhost / 127.0.0.1 / [::1] / 你的局域网网段。' \
    '例如识别到 192.168.x.x 时会写成 192.168.0.0/16；写完后，同一局域网里的手机、平板或电脑直接访问下面这条链接就行。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'lan_link')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'lan_link')"
  xmj_render_fact_line '自动识别 IPv4' "${auto_ip:-未识别到}"
  xmj_render_fact_line '当前准备链接' "${selected_ip:-还没选到}"
  xmj_render_fact_line '将写入白名单' "${selected_entry:-还没算出}"
  xmj_render_fact_line '已写入白名单' "${written_entry:-还没写}"
  xmj_render_fact_line '当前端口' "$current_port"
  xmj_render_fact_line '局域网链接' "${lan_url:-等你先写入一个局域网 IPv4}"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '写入当前局域网链接'
  xmj_render_action_item '2' '修改局域网 IP'
  xmj_render_action_item '8' '改回自动识别'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 直接写入 / 2 修改局域网 IP / 8 改回自动识别 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_lan_link_ip_page() {
  local auto_ip=''
  local written_entry=''
  local selected_ip=''
  local selected_entry=''

  auto_ip="$(xmj_tavern_setting_auto_lan_ip)"
  written_entry="$(xmj_tavern_setting_host_whitelist_lan_entry "$(xmj_tavern_setting_config_file)")"
  selected_ip="$(xmj_tavern_setting_selected_lan_ip)"
  selected_entry="$(xmj_tavern_setting_lan_cidr_from_ip "$selected_ip")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'lan_link_ip')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里填的是拿来判断局域网网段的本机 IPv4' \
    '猫猫会根据这个 IPv4 自动换算要写进 hostWhitelist 的局域网范围，例如 192.168.1.23 会写成 192.168.0.0/16。' \
    '只支持 192.168.x.x / 10.x.x.x / 172.16-31.x.x，写完后返回上一页再执行 1 写入当前局域网链接。'
  printf '\n'
  xmj_render_fact_line '自动识别 IPv4' "${auto_ip:-未识别到}"
  xmj_render_fact_line '当前准备写入' "${selected_ip:-还没选到}"
  xmj_render_fact_line '将写入白名单' "${selected_entry:-还没算出}"
  xmj_render_fact_line '已写入白名单' "${written_entry:-还没写}"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '0' '返回局域网链接'
  xmj_render_action_footer '直接输入局域网 IPv4 / 8 改回自动识别 / 0 返回局域网链接'
}

xmj_tavern_setting_apply_lan_link_fix() {
  local config_file=''
  local lan_ip=''
  local lan_entry=''
  local block_text=''
  local lan_url=''

  config_file="$(xmj_tavern_setting_config_file)"
  if [ -z "$config_file" ]; then
    xmj_font_set_notice 'warn' '没找到酒馆配置文件，先确认 SillyTavern 路径对不对。'
    return 1
  fi

  lan_ip="$(xmj_tavern_setting_selected_lan_ip)"
  if ! xmj_tavern_setting_is_private_ipv4 "$lan_ip"; then
    xmj_font_set_notice 'warn' '没识别到可用的局域网 IPv4，先去手动填写一个 192.168.x.x / 10.x.x.x / 172.16-31.x.x 地址。'
    return 1
  fi

  lan_entry="$(xmj_tavern_setting_lan_cidr_from_ip "$lan_ip")"
  if [ -z "$lan_entry" ]; then
    xmj_font_set_notice 'warn' "没法从 ${lan_ip} 推出局域网白名单范围，先检查这个地址是不是私网 IPv4。"
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'lan-link' "$config_file"; then
    return 1
  fi

  if ! xmj_tavern_setting_set_yaml_top_value "$config_file" 'listen' 'true'; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "listen 没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  block_text="$(xmj_tavern_setting_host_whitelist_lan_block "$lan_ip")"
  if ! xmj_tavern_setting_replace_yaml_section_block "$config_file" 'hostWhitelist' "$block_text"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "局域网白名单没写进去：$(xmj_display_path "$config_file")")"
    return 1
  fi

  XMJ_TAVERN_SETTING_LAN_IP="$lan_ip"
  lan_url="$(xmj_tavern_setting_lan_url "$lan_ip")"
  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把 listen 改成 true，并把 hostWhitelist 写成 localhost / 127.0.0.1 / [::1] / ${lan_entry}；同一局域网直接访问 ${lan_url}，重开酒馆后生效。")"
  return 0
}

xmj_tavern_setting_is_valid_user_folder_name() {
  local user_name=''

  user_name="$(xmj_tavern_setting_trim_spaces "${1:-}")"
  if [ -z "$user_name" ]; then
    return 1
  fi

  case "$user_name" in
    *[[:space:]]*|*/*|*\\*)
      return 1
      ;;
  esac

  return 0
}

xmj_tavern_setting_user_name() {
  local candidate=''

  for candidate in \
    "${XMJ_TAVERN_SETTING_USER_NAME:-}" \
    "${XMJ_TAVERN_SETTING_STUTTER_USER:-}" \
    "$(xmj_tavern_setting_default_user_name)"
  do
    candidate="$(xmj_tavern_setting_trim_spaces "$candidate")"
    if xmj_tavern_setting_is_valid_user_folder_name "$candidate"; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  printf '%s' 'default-user'
}

xmj_tavern_setting_user_folder_status_text() {
  local user_name=''
  local settings_file=''

  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  if [ -f "$settings_file" ]; then
    printf '当前：%s（settings.json 已找到）' "$user_name"
    return 0
  fi

  printf '当前：%s（settings.json 未找到）' "$user_name"
}

xmj_tavern_setting_update_stutter_user() {
  local user_name=''

  user_name="$(xmj_tavern_setting_trim_spaces "${1:-}")"
  if [ -z "$user_name" ]; then
    xmj_font_set_notice 'warn' '默认文件夹不能为空。'
    return 1
  fi

  if ! xmj_tavern_setting_is_valid_user_folder_name "$user_name"; then
    xmj_font_set_notice 'warn' '默认文件夹里别放空格或斜杠喵。'
    return 1
  fi

  if ! xmj_tavern_setting_backup_targets 'default-user-folder' "${XMJ_CONFIG_FILE:-}"; then
    return 1
  fi

  if ! xmj_config_upsert_value 'XMJ_TAVERN_SETTING_USER_NAME' "$user_name"; then
    xmj_font_set_notice 'warn' "$(xmj_tavern_setting_append_backup_note "默认文件夹没写回配置：$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")")"
    return 1
  fi

  XMJ_TAVERN_SETTING_STUTTER_USER="$user_name"
  xmj_font_set_notice 'success' "$(xmj_tavern_setting_append_backup_note "已把默认文件夹改成 data/${user_name}；之后相关设置都会按这个文件夹处理，不会自动改回 default-user。")"
  return 0
}

xmj_render_tavern_setting_user_folder_page() {
  local current_user=''
  local default_user=''
  local settings_file=''

  current_user="$(xmj_tavern_setting_user_name)"
  default_user="$(xmj_tavern_setting_default_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$current_user")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'user_folder')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这里填的是酒馆 data 目录下默认使用的用户文件夹' \
    '卡顿修复、聊天加载卡死修复、美化卡死修复都会优先按这个文件夹去找 settings.json。' \
    "设置后会写进小猫卷配置并持续保留；如果以后想改回去，手动再填一次 ${default_user} 就好。"
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'user_folder')"
  xmj_render_fact_line '当前默认文件夹' "$current_user"
  xmj_render_fact_line '默认值' "$default_user"
  xmj_render_fact_line '当前 settings.json' "$(xmj_display_path "$settings_file")"
  xmj_render_fact_line '面板配置文件' "$(xmj_display_path "${XMJ_CONFIG_FILE:-未生成}")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '直接输入文件夹名' '输入后会保存并返回酒馆设置'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '直接输入文件夹名 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_stutter_fix_page() {
  local config_file=''
  local user_name=''
  local settings_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'stutter_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项会一起改两处卡顿相关设置' \
    '第 1 步会把 config.yaml 里的 lazyLoadCharacters 改成 true；第 2 步会把默认文件夹对应 settings.json 里的 auto_load_chat 改成 false。' \
    '如果要换 data 用户文件夹，请回到酒馆设置首页走 13 默认文件夹设置。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'stutter_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'stutter_fix')"
  xmj_render_fact_line '当前默认文件夹' "$user_name"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_chat_freeze_fix_page() {
  local config_file=''
  local user_name=''
  local settings_file=''

  config_file="$(xmj_tavern_setting_config_file)"
  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'chat_freeze_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项专门处理一进酒馆就被聊天自动加载卡住的情况' \
    '猫猫会把默认文件夹对应 settings.json 里的 auto_load_chat 改成 false，再把 config.yaml 里的 lazyLoadCharacters 改成 true。' \
    '如果要换 data 用户文件夹，请回到酒馆设置首页走 13 默认文件夹设置。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'chat_freeze_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'chat_freeze_fix')"
  xmj_render_fact_line '当前默认文件夹' "$user_name"
  xmj_render_fact_line '配置文件' "$(xmj_display_path "${config_file:-未找到}")"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '立即执行修复'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}

xmj_render_tavern_setting_beautify_freeze_fix_page() {
  local user_name=''
  local settings_file=''
  local theme_value=''
  local custom_css=''

  user_name="$(xmj_tavern_setting_user_name)"
  settings_file="$(xmj_tavern_setting_user_settings_file "$user_name")"
  theme_value="$(xmj_tavern_setting_json_string_value "$settings_file" 'theme')"
  custom_css="$(xmj_tavern_setting_json_string_value "$settings_file" 'custom_css')"
  if [ -z "$custom_css" ]; then
    custom_css="$(xmj_tavern_setting_json_string_value "$settings_file" 'customCss')"
  fi

  xmj_clear_screen
  xmj_render_header
  xmj_render_page_title "$(xmj_tavern_setting_view_title 'beautify_freeze_fix')" 'tavern setting' 'setting'
  printf '\n'
  xmj_render_setting_card \
    '这项专门处理主题或自定义 CSS 把酒馆界面卡死的情况' \
    '猫猫会把默认文件夹对应 settings.json 里的 theme 改回 Dark Lite，并把 custom_css 清空。' \
    '如果要换 data 用户文件夹，请回到酒馆设置首页走 13 默认文件夹设置。'
  printf '\n'
  xmj_render_fact_line '项目编号' "$(xmj_tavern_setting_view_id 'beautify_freeze_fix')"
  xmj_render_fact_line '当前状态' "$(xmj_tavern_setting_status_text 'beautify_freeze_fix')"
  xmj_render_fact_line '当前默认文件夹' "$user_name"
  xmj_render_fact_line '当前主题' "${theme_value:-未读到}"
  xmj_render_fact_line 'custom_css' "${custom_css:+有内容}${custom_css:-空的}"
  xmj_render_fact_line '设置文件' "$(xmj_display_path "$settings_file")"
  xmj_render_notice_line
  printf '\n'
  xmj_render_action_item '1' '切回安全主题'
  xmj_render_action_item '0' '返回酒馆设置'
  xmj_render_action_footer '输入 1 执行修复 / 0 返回酒馆设置'
}
