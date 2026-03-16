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
    stutter_fix_user)
      xmj_render_tavern_setting_stutter_fix_user_page
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
  printf '  %b酒馆设置现在一共收进 12 项，网络访问相关的内容已经拆成“安全修复”和“局域网链接”两条。%b\n' "$XMJ_WHITE" "$XMJ_RESET"
  printf '  %b只想本机玩就走 10 安全修复；想让同一局域网里的手机、平板或电脑连进来，就走 12 局域网链接。%b\n' "$XMJ_MIST" "$XMJ_RESET"
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
        *)
          xmj_font_set_notice 'warn' '仅支持输入 1 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10 / 11 / 12 / 0。'
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
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_USER_RETURN_VIEW='stutter_fix'
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix_user'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 0。'
          ;;
      esac
      ;;
    stutter_fix_user)
      case "$input" in
        0)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_NEXT_VIEW="${XMJ_TAVERN_SETTING_USER_RETURN_VIEW:-stutter_fix}"
          ;;
        '')
          xmj_font_set_notice 'warn' '用户名不能为空。'
          ;;
        *)
          if xmj_tavern_setting_update_stutter_user "$input"; then
            XMJ_TAVERN_SETTING_NEXT_VIEW="${XMJ_TAVERN_SETTING_USER_RETURN_VIEW:-stutter_fix}"
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
        2)
          xmj_font_clear_notice
          XMJ_TAVERN_SETTING_USER_RETURN_VIEW="$view"
          XMJ_TAVERN_SETTING_NEXT_VIEW='stutter_fix_user'
          ;;
        *)
          xmj_font_set_notice 'warn' '这一页只支持输入 1 / 2 / 0。'
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
