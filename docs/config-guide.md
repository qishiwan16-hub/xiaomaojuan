# 小猫卷配置教程

这份教程面向 Termux 用户，重点说明小猫卷面板的启动配置怎么用、配置文件在哪、第一次运行会发生什么，以及常见问题怎么处理。

---

## 1. 配置文件位置

小猫卷默认读取下面这个文件：

```bash
config/xiaomaojuan.conf
```

如果你在项目根目录里，一般可以这样打开：

```bash
nano config/xiaomaojuan.conf
```

如果你还没进到脚本目录，可以先进入项目目录：

```bash
cd /你的/小猫卷目录
nano config/xiaomaojuan.conf
```

---

## 2. 怎么启动

在项目根目录执行：

```bash
chmod +x ./xiaomaojuan.sh
./xiaomaojuan.sh
```

说明：

- 脚本会自动识别自己的根目录。
- 即使你不是从脚本所在目录启动，它也会尽量按脚本真实位置去找 `lib/`、`config/`、`docs/`。
- 当前版本仍然是面板底座，菜单业务页还是占位页，不会真的执行更新、备份、恢复、安装依赖等动作。

---

## 3. 第一次运行会发生什么

启动时会按下面顺序处理：

1. 自动定位脚本根目录。
2. 检查 `config/` 目录是否存在，不存在就自动创建。
3. 检查 `config/xiaomaojuan.conf` 是否存在。
4. 如果配置文件不存在，会自动生成默认配置文件。
5. 读取配置并校验关键项目。
6. 自动检查备份目录，不存在就自动创建。
7. 检查 SillyTavern 路径是否存在。
8. 如果有提示或首次初始化信息，会先显示一页启动摘要，然后再进入首页。

如果启动失败：

- 不会直接炸出难看的报错堆栈；
- 会显示友好的启动失败提示；
- 会告诉你配置文件位置和教程位置，方便你直接修改。

---

## 4. 默认配置示例

`config/xiaomaojuan.conf` 默认内容大致如下：

```bash
XMJ_SCRIPT_NAME="小猫卷"
XMJ_SCRIPT_AUTHOR="meoroll"
XMJ_TARGET_PROJECT="SillyTavern"
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="backups"
XMJ_THEME_MODE="pastel"
XMJ_RUNTIME_ENV="Termux / Android / Bash"
```

你只需要改成自己的实际情况即可。

---

## 5. 每个关键配置项是干什么的

### 5.1 `XMJ_SCRIPT_NAME`

脚本显示名称。

作用：

- 显示在首页头部；
- 显示在信息区；
- 只是展示用途，不影响业务逻辑。

示例：

```bash
XMJ_SCRIPT_NAME="小猫卷"
```

---

### 5.2 `XMJ_SCRIPT_AUTHOR`

作者名称。

作用：

- 显示在头部和信息区；
- 只是展示用途。

示例：

```bash
XMJ_SCRIPT_AUTHOR="meoroll"
```

---

### 5.3 `XMJ_TARGET_PROJECT`

目标项目名称。

作用：

- 显示在首页；
- 用来说明这个一键脚本主要服务哪个项目。

示例：

```bash
XMJ_TARGET_PROJECT="SillyTavern"
```

---

### 5.4 `XMJ_SILLYTAVERN_PATH`

SillyTavern 的真实目录。

作用：

- 启动时用于检查目录是否存在；
- 首页信息区会显示这个路径；
- 当前版本不会真的去更新或操作这个目录，但后续扩展时通常会依赖这里。

示例：

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
```

如果你装在别的位置，比如：

```bash
XMJ_SILLYTAVERN_PATH="/data/data/com.termux/files/home/my-st/SillyTavern"
```

注意：

- 可以写绝对路径；
- 也可以用 `$HOME`；
- 也支持 `~/目录名` 这种写法；
- 如果路径不存在，脚本会给温和提示，但不会强行退出。

---

### 5.5 `XMJ_BACKUP_DIR`

备份目录。

作用：

- 启动时会检查这个目录；
- 如果不存在，会自动创建；
- 首页信息区会显示这个目录状态；
- 当前版本只是准备底座，不会真的执行备份逻辑。

示例 1：使用相对路径

```bash
XMJ_BACKUP_DIR="backups"
```

这表示备份目录最终会按“脚本根目录/backups”处理。

示例 2：使用绝对路径

```bash
XMJ_BACKUP_DIR="$HOME/xmj-backups"
```

---

### 5.6 `XMJ_THEME_MODE`

主题模式。

当前可选值：

- `pastel`
- `moonlight`

示例：

```bash
XMJ_THEME_MODE="pastel"
```

或者：

```bash
XMJ_THEME_MODE="moonlight"
```

说明：

- `pastel` 偏粉蓝白；
- `moonlight` 偏蓝紫月光；
- 如果你写错了，脚本会自动回退到 `pastel`，并给出提示。

---

### 5.7 `XMJ_RUNTIME_ENV`

运行环境说明。

作用：

- 只用于首页展示；
- 方便你标记当前脚本面向的环境。

示例：

```bash
XMJ_RUNTIME_ENV="Termux / Android / Bash"
```

你也可以改成：

```bash
XMJ_RUNTIME_ENV="Termux / Android 14 / Bash"
```

---

## 6. 怎么修改配置

### 方法一：直接编辑

```bash
nano config/xiaomaojuan.conf
```

修改完成后：

- 按 `Ctrl + O` 保存；
- 回车确认；
- 按 `Ctrl + X` 退出。

然后重新运行：

```bash
./xiaomaojuan.sh
```

---

### 方法二：先复制一份再改

如果你想先做个自己的测试配置：

```bash
cp config/xiaomaojuan.conf config/xiaomaojuan.conf.bak
nano config/xiaomaojuan.conf
```

注意：当前脚本不会自动读取 `.bak` 文件，只会读取正式的 `config/xiaomaojuan.conf`。

---

## 7. 首页现在会显示什么

现在首页信息区会优先读取真实配置，而不是全部写死。通常会显示：

- 脚本名称
- 作者
- 运行环境
- 目标项目
- SillyTavern 路径及状态
- 备份目录及状态
- 当前配置状态
- 当前主题模式

也就是说，你改完配置后，重新运行脚本，首页展示会跟着变化。

---

## 8. 常见问题

### 8.1 运行后提示找不到 SillyTavern 目录

这通常说明：

- `XMJ_SILLYTAVERN_PATH` 写错了；
- 你还没有安装 SillyTavern；
- 目录还没准备好。

处理方法：

1. 打开配置文件：

```bash
nano config/xiaomaojuan.conf
```

2. 检查这一行：

```bash
XMJ_SILLYTAVERN_PATH="你的实际路径"
```

3. 保存后重新运行脚本。

说明：这类情况目前只会提示，不会阻止你进入面板。

---

### 8.2 备份目录没有提前创建怎么办

不用手动准备。

只要 `XMJ_BACKUP_DIR` 配置正常，脚本启动时会尝试自动创建这个目录。

如果目录创建失败，通常是：

- 路径写错；
- 没有权限；
- 路径指向了不该写入的位置。

建议先改成比较稳妥的写法，例如：

```bash
XMJ_BACKUP_DIR="$HOME/xmj-backups"
```

---

### 8.3 主题没生效怎么办

先检查：

```bash
XMJ_THEME_MODE="pastel"
```

或：

```bash
XMJ_THEME_MODE="moonlight"
```

不要写成别的值。

如果写成错误值，脚本会自动回退到 `pastel`。

---

### 8.4 我从别的目录运行脚本，会不会路径乱掉

当前启动逻辑已经专门处理了这个问题。

脚本会优先按自己的真实位置定位根目录，再去找：

- `lib/`
- `config/`
- `docs/`

所以一般不会因为你当前所在目录不同而导致路径错乱。

---

### 8.5 为什么菜单点进去还是占位页

这是当前版本的设计边界，不是故障。

当前版本只完成了：

- 面板框架
- 配置加载
- 启动校验
- 首次运行体验
- 首页真实配置展示

还没有实现：

- 真正的一键更新
- 版本回退
- 真实备份/恢复
- 依赖安装
- 自动修复

所以现在的业务菜单仍然只是占位页。

---

## 9. 推荐修改流程

如果你是第一次用，直接按这个顺序来：

```bash
cd /你的/小猫卷目录
nano config/xiaomaojuan.conf
```

优先改这几个：

1. `XMJ_SILLYTAVERN_PATH`
2. `XMJ_BACKUP_DIR`
3. `XMJ_THEME_MODE`
4. `XMJ_RUNTIME_ENV`

保存后运行：

```bash
./xiaomaojuan.sh
```

如果首页信息区显示正常，说明启动配置已经基本完成。

---

## 10. 一句话总结

当前小猫卷已经不是纯展示壳子了，而是带有“根目录定位 + 集中配置加载 + 默认配置兜底 + 关键项校验 + 目录自动准备 + 启动提示”的一键脚本底座；但业务功能页目前仍然只是占位，不会真的操作你的项目。
