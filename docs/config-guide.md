# 小猫卷配置教程

这份文档是给 Termux 用户看的配置说明书，用来帮你快速看懂、修改 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)。

先记住一件事：**真正生效的运行配置文件始终是 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)**。这份 Markdown 只是把当前配置项、示例和修改方法整理清楚，方便你直接照着改，不替代实际配置文件。

---

## 1. 文档用途说明

这份文档解决的是下面几件事：

- 告诉你真正要改哪个文件；
- 告诉你第一次运行脚本时会发生什么；
- 把当前所有配置项完整列出来；
- 告诉你每个配置项是干什么的；
- 给你几套能直接复制的常见改法；
- 出问题时，先从哪里查。

如果你只想让脚本按你的环境正常显示和读取配置，重点看这几个部分：

1. [`## 2. 配置文件位置`](docs/config-guide.md)
2. [`## 3. 首次运行会发生什么`](docs/config-guide.md)
3. [`## 4. 推荐修改顺序`](docs/config-guide.md)
4. [`## 5. 完整配置示例`](docs/config-guide.md)
5. [`## 6. 配置项逐项说明`](docs/config-guide.md)

---

## 2. 配置文件位置

真正生效的配置文件是：

```bash
config/xiaomaojuan.conf
```

如果你已经进入小猫卷项目目录，直接编辑：

```bash
nano config/xiaomaojuan.conf
```

如果你还没进入项目目录，先进入再改：

```bash
cd /你的/小猫卷目录
nano config/xiaomaojuan.conf
```

修改完成后重新运行脚本即可生效：

```bash
./xiaomaojuan.sh
```

### 这一节要点

- 要改的是 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)，不是这份 [`docs/config-guide.md`](docs/config-guide.md)；
- 这份文档是教程，配置文件才是真正被脚本读取的内容；
- 改完配置后，需要重新执行 [`./xiaomaojuan.sh`](xiaomaojuan.sh) 才会看到新效果。

---

## 3. 首次运行会发生什么

第一次运行 [`./xiaomaojuan.sh`](xiaomaojuan.sh) 时，脚本会按当前逻辑做这些事：

1. 自动定位脚本根目录；
2. 检查 [`config/`](config) 目录是否存在；
3. 检查 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf) 是否存在；
4. 如果配置文件不存在，会自动生成默认配置；
5. 读取配置内容并校验关键项；
6. 检查备份目录，不存在就尝试自动创建；
7. 检查 [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16) 指向的目录是否存在；
8. 如果有首次初始化信息或提示，会先显示启动摘要，再进入首页。

### 首次运行时你可能看到的情况

#### 情况 1：配置文件不存在

脚本会自动生成默认的 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)。这时你再打开它，按你的实际路径改掉就行。

#### 情况 2：SillyTavern 路径不存在

如果 [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16) 写错，脚本会提示你路径状态，但当前版本不会因为这个直接退出。

#### 情况 3：备份目录不存在

如果 [`XMJ_BACKUP_DIR`](config/xiaomaojuan.conf:20) 指向的目录不存在，脚本会尝试自动创建。

#### 情况 4：主题值写错

如果 [`XMJ_THEME_MODE`](config/xiaomaojuan.conf:24) 不是支持的值，脚本会回退到默认主题并给出提示。

---

## 4. 推荐修改顺序

第一次配置时，不要一上来全部乱改，按这个顺序最稳：

### 第一步：先改项目真实路径

优先改 [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16)。

这是最关键的一项。哪怕别的展示项先不动，这个路径也最好先写对。

### 第二步：再改备份目录

改 [`XMJ_BACKUP_DIR`](config/xiaomaojuan.conf:20)。

建议一开始先用你有权限写入、自己也容易找到的位置。

### 第三步：再选主题

改 [`XMJ_THEME_MODE`](config/xiaomaojuan.conf:24)。

当前只需要在 `pastel` 和 `moonlight` 里选一个。

### 第四步：最后改展示信息

按需调整这些展示项：

- [`XMJ_SCRIPT_NAME`](config/xiaomaojuan.conf:6)
- [`XMJ_SCRIPT_AUTHOR`](config/xiaomaojuan.conf:9)
- [`XMJ_TARGET_PROJECT`](config/xiaomaojuan.conf:12)
- [`XMJ_RUNTIME_ENV`](config/xiaomaojuan.conf:27)

### 推荐顺序总结

```text
1. XMJ_SILLYTAVERN_PATH
2. XMJ_BACKUP_DIR
3. XMJ_THEME_MODE
4. XMJ_RUNTIME_ENV
5. XMJ_SCRIPT_NAME / XMJ_SCRIPT_AUTHOR / XMJ_TARGET_PROJECT
```

改完后重新运行：

```bash
./xiaomaojuan.sh
```

如果首页里显示的路径、主题、环境信息都正常，说明配置已经基本完成。

---

## 5. 完整配置示例

下面这份示例按当前 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf) 的实际字段整理，可以直接对照你的文件检查：

```bash
# 小猫卷配置文件
# 修改后重新运行 ./xiaomaojuan.sh 即可生效。
# 路径支持写成绝对路径，也支持使用 $HOME 或 ~/ 开头。

# 脚本显示名称，会出现在首页和标题区。
XMJ_SCRIPT_NAME="小猫卷"

# 作者名称，只用于展示。
XMJ_SCRIPT_AUTHOR="meoroll"

# 目标项目名称，只用于展示。
XMJ_TARGET_PROJECT="SillyTavern"

# SillyTavern 实际目录。
# 如果你装在别的位置，请改成自己的真实路径。
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"

# 备份目录。
# 可以写相对路径，例如 backups；相对路径会自动以脚本根目录为基准。
XMJ_BACKUP_DIR="backups"

# 主题模式。
# 可选值：pastel / moonlight
XMJ_THEME_MODE="pastel"

# 当前运行环境说明，会显示在首页信息区。
XMJ_RUNTIME_ENV="Termux / Android / Bash"

# 内置 Termux 字体预设名称。
XMJ_TERMUX_FONT_PRESET_NAME="霞鹜文楷等宽"

# 内置 Termux 字体预设下载地址。
XMJ_TERMUX_FONT_PRESET_URL="https://raw.githubusercontent.com/lxgw/LxgwWenKai/main/fonts/TTF/LXGWWenKaiMono-Regular.ttf"

# 内置 Termux 字体预设 MD5，用于校验下载结果。
XMJ_TERMUX_FONT_PRESET_MD5="612c16a3b40d91695635749c1493e02f"
```

### 复制时注意

- 配置项左右不要乱加空格；
- 字符串保持双引号最稳；
- 路径里如果有空格，也放在双引号里；
- 改的是 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)，不是把上面这段粘贴到别的文件里。

---

## 6. 配置项逐项说明

下面按当前配置文件中的字段逐项解释。

### 6.1 [`XMJ_SCRIPT_NAME`](config/xiaomaojuan.conf:6)

```bash
XMJ_SCRIPT_NAME="小猫卷"
```

作用：

- 控制脚本显示名称；
- 会出现在首页和标题区域；
- 只影响展示，不影响功能逻辑。

什么时候需要改：

- 你想把面板显示名改成自己的名字；
- 你自己二次分发时想改标题。

常见写法：

```bash
XMJ_SCRIPT_NAME="小猫卷"
XMJ_SCRIPT_NAME="小猫卷面板"
XMJ_SCRIPT_NAME="我的 ST 管理面板"
```

### 6.2 [`XMJ_SCRIPT_AUTHOR`](config/xiaomaojuan.conf:9)

```bash
XMJ_SCRIPT_AUTHOR="meoroll"
```

作用：

- 显示作者名称；
- 只用于页面展示。

什么时候需要改：

- 你自己维护一份改版时；
- 你想把显示作者改成自己的署名。

常见写法：

```bash
XMJ_SCRIPT_AUTHOR="meoroll"
XMJ_SCRIPT_AUTHOR="你的名字"
```

### 6.3 [`XMJ_TARGET_PROJECT`](config/xiaomaojuan.conf:12)

```bash
XMJ_TARGET_PROJECT="SillyTavern"
```

作用：

- 显示当前脚本主要服务哪个项目；
- 也是展示用途。

什么时候需要改：

- 你把这套面板改成服务别的项目时；
- 你只是想调整首页上的项目名。

常见写法：

```bash
XMJ_TARGET_PROJECT="SillyTavern"
XMJ_TARGET_PROJECT="SillyTavern Dev"
```

### 6.4 [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16)

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
```

作用：

- 指定 SillyTavern 的真实目录；
- 启动时会检查这个目录是否存在；
- 首页信息区会显示这个路径和状态；
- 当前版本主要用于校验和展示，后续扩展功能通常也会依赖这里。

这是最优先要改对的一项。

支持的写法：

- 绝对路径；
- [`$HOME`](config/xiaomaojuan.conf:3) 开头的路径；
- [`~/`](config/xiaomaojuan.conf:3) 开头的路径。

示例：

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_SILLYTAVERN_PATH="/data/data/com.termux/files/home/SillyTavern"
XMJ_SILLYTAVERN_PATH="$HOME/projects/SillyTavern"
XMJ_SILLYTAVERN_PATH="~/SillyTavern"
```

不建议这样写：

```bash
XMJ_SILLYTAVERN_PATH=SillyTavern
```

原因：

- 相对路径容易让你自己后面看不懂；
- 路径检查时也更容易误判；
- Termux 下建议直接写完整路径或 [`$HOME`](config/xiaomaojuan.conf:3) 路径。

### 6.5 [`XMJ_BACKUP_DIR`](config/xiaomaojuan.conf:20)

```bash
XMJ_BACKUP_DIR="backups"
```

作用：

- 指定备份目录；
- 启动时会检查目录状态；
- 如果目录不存在，脚本会尝试自动创建；
- 当前版本主要是准备目录和展示状态。

支持两种思路：

#### 写相对路径

```bash
XMJ_BACKUP_DIR="backups"
```

这表示最终会按“脚本根目录下的 [`backups/`](backups)”来处理。

适合：

- 想把备份跟脚本放一起；
- 想迁移项目时一起打包走。

#### 写绝对路径

```bash
XMJ_BACKUP_DIR="$HOME/xmj-backups"
```

适合：

- 想把备份单独放到固定目录；
- 想避免脚本目录删除时把备份一起删掉。

常见示例：

```bash
XMJ_BACKUP_DIR="backups"
XMJ_BACKUP_DIR="$HOME/xmj-backups"
XMJ_BACKUP_DIR="/data/data/com.termux/files/home/storage/shared/xmj-backups"
```

### 6.6 [`XMJ_THEME_MODE`](config/xiaomaojuan.conf:24)

```bash
XMJ_THEME_MODE="pastel"
```

作用：

- 控制界面主题模式；
- 当前支持值只有两个：`pastel`、`moonlight`。

可选值：

```bash
XMJ_THEME_MODE="pastel"
XMJ_THEME_MODE="moonlight"
```

说明：

- `pastel`：偏柔和、浅色、粉蓝风格；
- `moonlight`：偏蓝紫、夜间感更强；
- 如果写成别的值，脚本会回退到默认值并提示你。

### 6.7 [`XMJ_RUNTIME_ENV`](config/xiaomaojuan.conf:27)

```bash
XMJ_RUNTIME_ENV="Termux / Android / Bash"
```

作用：

- 用来显示当前运行环境说明；
- 只影响首页展示，不影响脚本逻辑。

适合填写什么：

- 你的设备环境；
- 你的系统版本；
- 你自己想标记的运行说明。

常见写法：

```bash
XMJ_RUNTIME_ENV="Termux / Android / Bash"
XMJ_RUNTIME_ENV="Termux / Android 14 / Bash"
XMJ_RUNTIME_ENV="Termux / Samsung / Bash"
```

### 6.8 [`XMJ_TERMUX_FONT_PRESET_NAME`](config/xiaomaojuan.conf:30)

```bash
XMJ_TERMUX_FONT_PRESET_NAME="霞鹜文楷等宽"
```

作用：

- 用来显示设置中心 > 字体管理里的内置字体名称；
- 当前默认预设是霞鹜文楷等宽。

### 6.9 [`XMJ_TERMUX_FONT_PRESET_URL`](config/xiaomaojuan.conf:33)

```bash
XMJ_TERMUX_FONT_PRESET_URL="https://raw.githubusercontent.com/lxgw/LxgwWenKai/main/fonts/TTF/LXGWWenKaiMono-Regular.ttf"
```

作用：

- 作为内置字体下载地址；
- 在设置中心 > 字体管理里选择安装内置字体时会用到这个地址。

说明：

- 这里最好填可直接下载 `.ttf` 的直链；
- 如果你后面想切别的字体，可以只改这一项和对应的 MD5。

### 6.10 [`XMJ_TERMUX_FONT_PRESET_MD5`](config/xiaomaojuan.conf:36)

```bash
XMJ_TERMUX_FONT_PRESET_MD5="612c16a3b40d91695635749c1493e02f"
```

作用：

- 用来校验下载下来的字体文件；
- 防止把错误页面或失效链接当成字体写进 `~/.termux/font.ttf`。

说明：

- 如果你替换了 `XMJ_TERMUX_FONT_PRESET_URL`，记得一起改这里的 MD5；
- 如果 MD5 对不上，脚本会拒绝应用该字体。

---

## 7. 怎么修改配置

如果你是第一次改，按下面做就行。

### 7.1 直接编辑

```bash
cd /你的/小猫卷目录
nano config/xiaomaojuan.conf
```

修改后保存：

- 按 `Ctrl + O`；
- 回车确认；
- 按 `Ctrl + X` 退出。

然后重新运行：

```bash
./xiaomaojuan.sh
```

### 7.2 改之前先备份一份

```bash
cp config/xiaomaojuan.conf config/xiaomaojuan.conf.bak
nano config/xiaomaojuan.conf
```

注意：脚本只会读取正式文件 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)，不会自动读取 `.bak` 文件。

---

## 8. 常见修改示例

下面是几套 Termux 下最常见、可以直接参考的写法。

### 示例 1：最常规的 Termux 安装

适合 SillyTavern 装在家目录里。

```bash
XMJ_SCRIPT_NAME="小猫卷"
XMJ_SCRIPT_AUTHOR="meoroll"
XMJ_TARGET_PROJECT="SillyTavern"
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="backups"
XMJ_THEME_MODE="pastel"
XMJ_RUNTIME_ENV="Termux / Android / Bash"
```

### 示例 2：SillyTavern 装在自定义目录

```bash
XMJ_SCRIPT_NAME="小猫卷"
XMJ_SCRIPT_AUTHOR="meoroll"
XMJ_TARGET_PROJECT="SillyTavern"
XMJ_SILLYTAVERN_PATH="$HOME/projects/SillyTavern"
XMJ_BACKUP_DIR="$HOME/xmj-backups"
XMJ_THEME_MODE="moonlight"
XMJ_RUNTIME_ENV="Termux / Android 14 / Bash"
```

### 示例 3：备份单独放到共享存储目录

前提：你已经在 Termux 里执行过 `termux-setup-storage`，并且有权限访问共享存储。

```bash
XMJ_SCRIPT_NAME="小猫卷"
XMJ_SCRIPT_AUTHOR="meoroll"
XMJ_TARGET_PROJECT="SillyTavern"
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="/data/data/com.termux/files/home/storage/shared/xmj-backups"
XMJ_THEME_MODE="pastel"
XMJ_RUNTIME_ENV="Termux / Android / Shared Storage"
```

### 示例 4：只改最关键三项

如果你不想动展示信息，只改这三项也可以：

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="$HOME/xmj-backups"
XMJ_THEME_MODE="moonlight"
```

---

## 9. 常见问题

### 9.1 为什么我改了这份文档，脚本还是没变化

因为真正生效的是 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)，不是 [`docs/config-guide.md`](docs/config-guide.md)。

这份文档只是说明书，不会被脚本当成配置读取。

### 9.2 改完配置后什么时候生效

改完 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf) 后，重新运行一次：

```bash
./xiaomaojuan.sh
```

当前不是热加载，改完不会自动刷新。

### 9.3 提示找不到 SillyTavern 目录怎么办

先检查 [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16)。

建议直接在 Termux 里确认目录是否存在，再把同样的路径写进配置文件。

例如：

```bash
ls "$HOME/SillyTavern"
```

如果目录实际不在这里，就改成你的真实路径。

### 9.4 备份目录会自动创建吗

会尝试自动创建。

前提是：

- [`XMJ_BACKUP_DIR`](config/xiaomaojuan.conf:20) 写法有效；
- 目标位置你有写入权限。

如果你把目录写到没有权限的位置，自动创建也会失败。

### 9.5 路径到底写相对路径还是绝对路径

建议这样理解：

- [`XMJ_SILLYTAVERN_PATH`](config/xiaomaojuan.conf:16) 优先写绝对路径或 [`$HOME`](config/xiaomaojuan.conf:3) 路径；
- [`XMJ_BACKUP_DIR`](config/xiaomaojuan.conf:20) 可以写相对路径，也可以写绝对路径。

如果你想少出错，最稳的是：

- 项目路径写完整；
- 备份路径按你的使用习惯选择。

### 9.6 主题为什么没变化

检查 [`XMJ_THEME_MODE`](config/xiaomaojuan.conf:24) 是否写成了支持值：

```bash
XMJ_THEME_MODE="pastel"
```

或：

```bash
XMJ_THEME_MODE="moonlight"
```

如果写成别的值，脚本会回退到默认主题。

### 9.7 我从别的目录运行脚本，会不会找不到配置

当前逻辑已经考虑了这个问题。

脚本会先定位自己的根目录，再去找：

- [`config/`](config)
- [`lib/`](lib)
- [`docs/`](docs)

所以一般不会因为你当前所在目录不同，就把配置文件找错。

### 9.8 当前版本会真的执行更新、恢复、安装这些动作吗

当前重点还是面板底座和配置加载。

现在已经具备的是：

- 根目录定位；
- 配置读取；
- 默认配置生成；
- 启动校验；
- 首页真实配置展示；
- 备份目录自动准备。

当前还不是完整业务实现页，所以一些菜单现在仍然是占位用途。

---

## 10. 最短使用流程

如果你只想最快配置好，照着下面做：

```bash
cd /你的/小猫卷目录
nano config/xiaomaojuan.conf
```

最少先改这三项：

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="$HOME/xmj-backups"
XMJ_THEME_MODE="pastel"
```

保存后运行：

```bash
./xiaomaojuan.sh
```

看到首页信息区显示正常，就说明配置已经读进去了。

---

## 11. 一句话记住

**教程看 [`docs/config-guide.md`](docs/config-guide.md)，真正生效改 [`config/xiaomaojuan.conf`](config/xiaomaojuan.conf)。**
