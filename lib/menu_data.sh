xmj_theme_label() {
  case "${XMJ_THEME_MODE:-pastel}" in
    moonlight)
      printf '%s' '月光蓝紫系'
      ;;
    *)
      printf '%s' '粉蓝白系'
      ;;
  esac
}

xmj_display_path() {
  local raw_path="${1:-}"

  if [ -z "$raw_path" ]; then
    printf '%s' '未设置'
    return 0
  fi

  if [ -n "${HOME:-}" ]; then
    printf '%s' "${raw_path/#$HOME/~}"
    return 0
  fi

  printf '%s' "$raw_path"
}

xmj_dir_state() {
  local dir_path="${1:-}"
  local ok_text="${2:-已就绪}"
  local miss_text="${3:-未找到}"

  if [ -n "$dir_path" ] && [ -d "$dir_path" ]; then
    printf '%s' "$ok_text"
    return 0
  fi

  printf '%s' "$miss_text"
}

xmj_load_menu_data() {
  XMJ_SECTION_ORDER=(
    "update"
    "backup"
    "dependency"
    "extend"
    "setting"
    "about"
  )

  declare -gA XMJ_SECTION_TITLE=()
  declare -gA XMJ_SECTION_DECOR=()

  XMJ_SECTION_TITLE[info]='信息公开'
  XMJ_SECTION_TITLE[update]='更新维护'
  XMJ_SECTION_TITLE[backup]='备份恢复'
  XMJ_SECTION_TITLE[dependency]='依赖环境'
  XMJ_SECTION_TITLE[extend]='扩展脚本'
  XMJ_SECTION_TITLE[setting]='设置中心'
  XMJ_SECTION_TITLE[about]='关于小猫卷'

  XMJ_SECTION_DECOR[info]='✦ ˖ ·'
  XMJ_SECTION_DECOR[update]='✧ ೃ ·'
  XMJ_SECTION_DECOR[backup]='✦ ﾟ ·'
  XMJ_SECTION_DECOR[dependency]='✧ ˚ ·'
  XMJ_SECTION_DECOR[extend]='✦ ₊ ·'
  XMJ_SECTION_DECOR[setting]='✧ ｡ ·'
  XMJ_SECTION_DECOR[about]='✦ ⋆ ·'

  XMJ_INFO_ORDER=(
    '名称'
    '作者'
    '环境'
    '目标'
    'SillyTavern'
    '备份'
    '状态'
    '主题'
  )

  declare -gA XMJ_INFO_VALUE=()
  XMJ_INFO_VALUE['名称']="${XMJ_SCRIPT_NAME:-小猫卷}"
  XMJ_INFO_VALUE['作者']="${XMJ_SCRIPT_AUTHOR:-meoroll}"
  XMJ_INFO_VALUE['环境']="${XMJ_RUNTIME_ENV:-Termux / Android / Bash}"
  XMJ_INFO_VALUE['目标']="${XMJ_TARGET_PROJECT:-SillyTavern}"
  XMJ_INFO_VALUE['SillyTavern']="状态：$(xmj_dir_state "${XMJ_SILLYTAVERN_PATH:-}" '已发现' '待确认')"
  XMJ_INFO_VALUE['备份']="状态：$(xmj_dir_state "$(xmj_maintenance_backup_dir)" '已就绪' '待创建')"
  XMJ_INFO_VALUE['状态']="$(xmj_config_status_text)"
  XMJ_INFO_VALUE['主题']="$(xmj_theme_label)"

  XMJ_MENU_IDS=(
    '01' '02' '03' '04' '05' '06'
    '07' '08' '09' '10'
    '11' '12' '13' '14'
    '15' '16' '17' '18'
    '19' '20' '21' '22'
    '23' '24' '25' '00'
  )

  declare -gA XMJ_MENU_LABEL=()
  declare -gA XMJ_MENU_SECTION=()

  XMJ_MENU_LABEL['01']='启动酒馆'
  XMJ_MENU_LABEL['02']='一键更新'
  XMJ_MENU_LABEL['03']='切换版本'
  XMJ_MENU_LABEL['04']='卸载重装'
  XMJ_MENU_LABEL['05']='更新记录'
  XMJ_MENU_LABEL['06']='教程说明'
  XMJ_MENU_LABEL['07']='创建备份'
  XMJ_MENU_LABEL['08']='备份列表'
  XMJ_MENU_LABEL['09']='恢复数据'
  XMJ_MENU_LABEL['10']='清理旧档'
  XMJ_MENU_LABEL['11']='安装依赖'
  XMJ_MENU_LABEL['12']='环境检查'
  XMJ_MENU_LABEL['13']='异常修复'
  XMJ_MENU_LABEL['14']='版本状态'
  XMJ_MENU_LABEL['15']='脚本入口'
  XMJ_MENU_LABEL['16']='工具合集'
  XMJ_MENU_LABEL['17']='后续追加'
  XMJ_MENU_LABEL['18']='预留空位'
  XMJ_MENU_LABEL['19']='设置中心'
  XMJ_MENU_LABEL['20']='酒馆设置'
  XMJ_MENU_LABEL['21']='字体管理'
  XMJ_MENU_LABEL['22']='基础设置'
  XMJ_MENU_LABEL['23']='状态信息'
  XMJ_MENU_LABEL['24']='关于面板'
  XMJ_MENU_LABEL['25']='作者信息'
  XMJ_MENU_LABEL['00']='退出面板'

  XMJ_MENU_SECTION['01']='update'
  XMJ_MENU_SECTION['02']='update'
  XMJ_MENU_SECTION['03']='update'
  XMJ_MENU_SECTION['04']='update'
  XMJ_MENU_SECTION['05']='update'
  XMJ_MENU_SECTION['06']='update'
  XMJ_MENU_SECTION['07']='backup'
  XMJ_MENU_SECTION['08']='backup'
  XMJ_MENU_SECTION['09']='backup'
  XMJ_MENU_SECTION['10']='backup'
  XMJ_MENU_SECTION['11']='dependency'
  XMJ_MENU_SECTION['12']='dependency'
  XMJ_MENU_SECTION['13']='dependency'
  XMJ_MENU_SECTION['14']='dependency'
  XMJ_MENU_SECTION['15']='extend'
  XMJ_MENU_SECTION['16']='extend'
  XMJ_MENU_SECTION['17']='extend'
  XMJ_MENU_SECTION['18']='extend'
  XMJ_MENU_SECTION['19']='setting'
  XMJ_MENU_SECTION['20']='setting'
  XMJ_MENU_SECTION['21']='setting'
  XMJ_MENU_SECTION['22']='setting'
  XMJ_MENU_SECTION['23']='about'
  XMJ_MENU_SECTION['24']='about'
  XMJ_MENU_SECTION['25']='about'
  XMJ_MENU_SECTION['00']='about'
}

xmj_menu_text() {
  local id="${1:-}"
  printf 'ʚ✞%s✞ɞ｜%s' "$id" "${XMJ_MENU_LABEL[$id]}"
}
