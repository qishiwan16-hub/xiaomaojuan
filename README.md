# 小猫卷

小猫卷是一个运行在 **Termux** 里的 Bash 一键脚本项目，当前还处于**预览 / 框架阶段**。

现阶段的重点不是提供完整业务能力，而是先把下面这些底座搭起来：

- 面板框架
- 配置读取与校验
- 启动流程
- 占位菜单页

所以，这个仓库现在更适合拿来**完成基础安装、看清项目结构、验证配置是否能正常读取**，而不是直接当成完整可用的运维脚本。

---

## 适用环境

- **Termux**
- **Android + Termux 自带 Bash 环境**
- 当前默认面向 **SillyTavern** 目录场景，相关路径在配置文件中设置

---

## 当前状态

### 已实现

当前版本已经具备：

- 根目录启动入口：`xiaomaojuan.sh`
- `lib/` 下的面板框架模块
- `config/xiaomaojuan.conf` 配置底座
- 启动时的配置读取、默认值补全与基础校验
- 备份目录检查与自动创建
- 首页信息展示
- 菜单占位页与占位跳转

### 还没有实现

当前版本**还没有接入真实业务逻辑**，包括但不限于：

- 一键更新
- 版本回退
- 真实备份
- 真实恢复
- 依赖安装
- 环境修复
- Git 更新 / 回滚等真实操作
- 菜单项背后的实际执行逻辑

看到菜单并不代表这些功能已经可用；目前大部分菜单仍然只是占位页。

---

## 项目结构

当前仓库的核心文件如下：

```text
xiaomaojuan.sh
config/xiaomaojuan.conf
docs/config-guide.md
lib/
```

作用分别是：

- `xiaomaojuan.sh`：脚本入口
- `config/xiaomaojuan.conf`：真正生效的配置文件
- `docs/config-guide.md`：配置说明文档
- `lib/`：面板、渲染、路由、配置处理等模块

---

## 安装方式

以下步骤默认你正在 **Termux** 中操作。

### 1. 安装基础工具

如果你的 Termux 里还没有 `git`，先安装：

```bash
pkg update
pkg install git nano
```

说明：

- `git` 用来克隆仓库
- `nano` 只是为了方便编辑配置，不是脚本业务依赖

### 2. 克隆仓库

```bash
git clone https://github.com/qishiwan16-hub/xiaomaojuan.git
cd xiaomaojuan
```

### 3. 赋予执行权限

```bash
chmod +x xiaomaojuan.sh
```

---

## 首次运行前准备

在第一次正式使用前，先处理配置文件。

### 1. 打开配置文件

```bash
nano config/xiaomaojuan.conf
```

### 2. 至少检查这几个配置项

```bash
XMJ_SILLYTAVERN_PATH="$HOME/SillyTavern"
XMJ_BACKUP_DIR="backups"
XMJ_THEME_MODE="pastel"
```

建议优先确认：

- `XMJ_SILLYTAVERN_PATH` 是否是你的真实目录
- `XMJ_BACKUP_DIR` 是否是你有权限写入的位置
- `XMJ_THEME_MODE` 是否为支持值：`pastel` 或 `moonlight`

### 3. 需要共享存储时先授权

如果你的备份目录想写到共享存储，先在 Termux 中执行：

```bash
termux-setup-storage
```

这一步只在你确实要访问手机共享存储时需要。

### 4. 配置说明文档位置

更详细的配置项说明，请直接看：

- `docs/config-guide.md`

真正生效的配置文件始终是：

- `config/xiaomaojuan.conf`

---

## 如何启动脚本

在项目根目录执行：

```bash
./xiaomaojuan.sh
```

如果你不想依赖执行权限，也可以这样启动：

```bash
bash xiaomaojuan.sh
```

---

## 首次运行后会发生什么

按当前版本的实际逻辑，脚本启动后会做这些事：

1. 自动定位项目根目录
2. 检查 `config/` 是否存在
3. 检查 `config/xiaomaojuan.conf` 是否存在
4. 如果配置文件缺失，会自动生成默认配置
5. 读取并校验配置内容
6. 检查备份目录，不存在时尝试自动创建
7. 检查 `XMJ_SILLYTAVERN_PATH` 指向的目录是否存在
8. 显示启动摘要，然后进入首页面板

需要注意的是：

- 如果 `XMJ_SILLYTAVERN_PATH` 写错，当前版本通常会给出提示，但不会直接把你拦在面板外
- 如果主题值写错，会自动回退到默认主题
- 改完配置后需要重新运行脚本，当前不是热加载

---

## 配置文件位置

### 生效配置文件

```text
config/xiaomaojuan.conf
```

### 配置说明文档

```text
docs/config-guide.md
```

请记住：

- **脚本读取的是 `config/xiaomaojuan.conf`**
- **`docs/config-guide.md` 只是教程，不会被脚本当成配置读取**

修改配置后，重新执行：

```bash
./xiaomaojuan.sh
```

---

## 简洁可复制的安装 / 启动示例

下面这组命令适合第一次在 Termux 里拉取并启动项目：

```bash
pkg update
pkg install git nano
git clone https://github.com/qishiwan16-hub/xiaomaojuan.git
cd xiaomaojuan
chmod +x xiaomaojuan.sh
nano config/xiaomaojuan.conf
./xiaomaojuan.sh
```

如果你已经改好配置，只需要：

```bash
cd xiaomaojuan
./xiaomaojuan.sh
```

---

## 常见注意事项

- 这是 **Termux** 项目，不是桌面 Linux 的通用发行版脚本说明
- 改配置要改 `config/xiaomaojuan.conf`，不要改 `docs/config-guide.md`
- `XMJ_SILLYTAVERN_PATH` 最好写真实路径，优先使用绝对路径或 `$HOME` 路径
- `XMJ_BACKUP_DIR` 可以写相对路径；相对路径会以项目根目录为基准
- 主题目前只支持 `pastel` 和 `moonlight`
- 改完配置后要重新运行 `./xiaomaojuan.sh` 才会生效
- 当前菜单大多是占位页，不会真的执行更新、回退、备份、恢复、依赖安装等动作
- 如果你把备份目录写到无权限位置，自动创建会失败
- 仓库里已经带有默认配置文件；只有在配置文件缺失时，脚本才会自动重新生成默认配置

---

## 一句话说明

**小猫卷当前是一个运行在 Termux 中的 Bash 面板预览框架，已经具备配置底座与占位页面，但还不是完整的真实功能脚本。**
