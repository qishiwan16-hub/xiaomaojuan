xmj_load_menu_data() {
  XMJ_SECTION_ORDER=(
    "info"
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
    '状态'
    '主题'
  )

  declare -gA XMJ_INFO_VALUE=()
  XMJ_INFO_VALUE['名称']='小猫卷'
  XMJ_INFO_VALUE['作者']='meoroll'
  XMJ_INFO_VALUE['环境']='Termux'
  XMJ_INFO_VALUE['目标']='SillyTavern'
  XMJ_INFO_VALUE['状态']='展示预览版'
  XMJ_INFO_VALUE['主题']='粉蓝白系'

  XMJ_MENU_IDS=(
    '01' '02' '03' '04'
    '05' '06' '07' '08'
    '09' '10' '11' '12'
    '13' '14' '15' '16'
    '17' '18' '19' '20'
    '21' '22' '23' '00'
  )

  declare -gA XMJ_MENU_LABEL=()
  declare -gA XMJ_MENU_SECTION=()

  XMJ_MENU_LABEL['01']='一键更新'
  XMJ_MENU_LABEL['02']='版本回退'
  XMJ_MENU_LABEL['03']='更新记录'
  XMJ_MENU_LABEL['04']='快速启动'
  XMJ_MENU_LABEL['05']='创建备份'
  XMJ_MENU_LABEL['06']='备份列表'
  XMJ_MENU_LABEL['07']='恢复数据'
  XMJ_MENU_LABEL['08']='清理旧档'
  XMJ_MENU_LABEL['09']='安装依赖'
  XMJ_MENU_LABEL['10']='环境检查'
  XMJ_MENU_LABEL['11']='异常修复'
  XMJ_MENU_LABEL['12']='版本状态'
  XMJ_MENU_LABEL['13']='脚本入口'
  XMJ_MENU_LABEL['14']='工具合集'
  XMJ_MENU_LABEL['15']='后续追加'
  XMJ_MENU_LABEL['16']='预留空位'
  XMJ_MENU_LABEL['17']='路径设置'
  XMJ_MENU_LABEL['18']='主题风格'
  XMJ_MENU_LABEL['19']='安全选项'
  XMJ_MENU_LABEL['20']='备份目录'
  XMJ_MENU_LABEL['21']='状态信息'
  XMJ_MENU_LABEL['22']='关于面板'
  XMJ_MENU_LABEL['23']='作者信息'
  XMJ_MENU_LABEL['00']='退出面板'

  XMJ_MENU_SECTION['01']='update'
  XMJ_MENU_SECTION['02']='update'
  XMJ_MENU_SECTION['03']='update'
  XMJ_MENU_SECTION['04']='update'
  XMJ_MENU_SECTION['05']='backup'
  XMJ_MENU_SECTION['06']='backup'
  XMJ_MENU_SECTION['07']='backup'
  XMJ_MENU_SECTION['08']='backup'
  XMJ_MENU_SECTION['09']='dependency'
  XMJ_MENU_SECTION['10']='dependency'
  XMJ_MENU_SECTION['11']='dependency'
  XMJ_MENU_SECTION['12']='dependency'
  XMJ_MENU_SECTION['13']='extend'
  XMJ_MENU_SECTION['14']='extend'
  XMJ_MENU_SECTION['15']='extend'
  XMJ_MENU_SECTION['16']='extend'
  XMJ_MENU_SECTION['17']='setting'
  XMJ_MENU_SECTION['18']='setting'
  XMJ_MENU_SECTION['19']='setting'
  XMJ_MENU_SECTION['20']='setting'
  XMJ_MENU_SECTION['21']='about'
  XMJ_MENU_SECTION['22']='about'
  XMJ_MENU_SECTION['23']='about'
  XMJ_MENU_SECTION['00']='about'
}

xmj_menu_text() {
  local id="${1:-}"
  printf 'ʚ✞%s✞ɞ｜%s' "$id" "${XMJ_MENU_LABEL[$id]}"
}
