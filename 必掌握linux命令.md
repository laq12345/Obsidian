---
lang: Linux
date: 2026-03-19
tags:
  - 编程
---
date:
date 命令后输入以“+”号开头的参数，即可按照指定格式输出系统的时间或日期

| 参数  | 作用                  |
| --- | ------------------- |
| %S  | 秒（00~59）            |
| %M  | 分钟（00~59）           |
| %H  | 小时（00~23）           |
| %I  | 小时（00~12）           |
| %m  | 月份（1~12）            |
| %p  | 显示出 AM 或PM          |
| %a  | 缩写的工作日名称（例如 Sun）    |
| %A  | 完整的工作日名称（例如 Sunday） |
| %b  | 缩写的月份名称（例如 Jan）     |
| %B  | 完整的月份名称（例如 January） |
| %y  | 简写年份（例如 25）         |
| %Y  | 完整年份（例如 2025）       |
| %d  | 本月中的第几天             |
| %j  | 今年中的第几天             |
| %n  | 换行符（相当于按下回车键）       |
| %t  | 跳格（相当于按下 Tab 键）     |
### date
date 命令中的参数%j 可用来查看今天是当年中的第几天。
```bash
root@linuxprobe:~# date "+%j"
138
```

### timedatectl


| 参数             | 作用      |
| -------------- | ------- |
| status         | 显示状态信息  |
| list-timezones | 列出已知时区  |
| set-time       | 设置系统时间  |
| set-timezone   | 设置生效时间  |
| set-ntp        | 设置NTP服务 |

### reboot
由于重启计算机这种操作会涉及硬件资源的管理权限，普通用户在执行该命令时可能会被拒绝，因此最好是**以 root 管理员**的身份来重启。

### poweroff

该命令也会涉及硬件资源的管理权限，因此最好还是以 **root 管理员**的身份来关闭计算机

### wget

| 参数  | 作用                     |
| --- | ---------------------- |
| -b  | 后台下载模式                 |
| -P  | 下载到指定目录                |
| -t  | 最大尝试次数                 |
| -c  | 断点续传                   |
| -p  | 下载页面所需的资源（如CSS，JS，图片等） |
| -r  | 递归下载                   |
### ps

| 参数  | 作用          |
| --- | ----------- |
| -a  | 显示所有进程      |
| -u  | 用户及其它详细信息   |
| -x  | 显示没有控制终端的进程 |


> **R（运行）**：进程正在运行或在运行队列中等待。
> 
> **S（中断）**：进程处于休眠中，当某个条件形成后或者接收到信号时，则脱离该状态。
> 
> **D（不可中断）**：进程处于不可中断睡眠状态，通常因等待 IO 资源释放而无法终止。
> 
> **Z（僵死）**：进程已经终止，但进程描述符依然存在，直到父进程调用 wait4()系统函数将进程释放。
> 
> **T（停止）**：进程收到停止信号后停止运行。

除了上面 5 种常见的进程状态，进程还有可能是**高优先级（<）、低优先级（N）、被锁进内存（L）、包含子进程（s）以及多线程（l）** 5 种补充形式。

ps aux的进程状态：

| USER | PID  | %CPU   | %MEM  | VSZ    | RSS    | TTY | STAT | START | TIME | COMMAND |
| ---- | ---- | ------ | ----- | ------ | ------ | --- | ---- | ----- | ---- | ------- |
| 用户   | 进程ID | CPU占用率 | 内存占用率 | 虚拟内存大小 | 常驻内存大小 | 终端  | 状态   | 启动时间  | 运行时间 | 命令      |

### top

> 第 1 行：系统时间、运行时间、登录终端数、系统负载（3 个数值分别为 1 分钟、5 分钟、15 分钟内的平均值，数值越小意味着负载越低）。
> 
> 第 2 行：进程总数、运行中的进程数、睡眠中的进程数、停止的进程数、僵死的进程数。
> 
> 第 3 行：用户占用资源百分比、系统内核占用资源百分比、已调整优先级的进程的资源占比、空闲资源百分比等。其中数据均为 CPU 数据并以百分比格式显示，例如“99.9 id”意味着有 99.9%的 CPU 资源处于空闲。
> 
> 第 4 行：物理内存总量、空闲内存量、已使用内存量、用于内核缓存的内存量。
> 
> 第 5 行：虚拟内存总量、空闲虚拟内存量、已使用虚拟内存量、预加载的内存量。

### nice

nice 命令用于调整进程的优先级，语法格式为“nice -n 优先级数字 服务名称”
在top 命令输出的结果中，PR 和 NI 值代表的是进程的优先级，数字越低（取值范围是−20~19），优先级越高。
```bash
root@linuxprobe:~# nice -n -20 bash
```

### pidof

pidof 命令用于查询某个指定服务进程的 PID，语法格式为“pidof [参数] 服务名称”。

### kill

kill 命令用于终止某个指定 PID 的服务进程，语法格式为“kill [参数] 进程的 PID”。

但有时系统会提示进程无法被终止，此时可以添加参数-9（SIGKILL 信号），此信号为系统中强制终止进程的最高级别命令，进程无法抗拒：
```bash
root@linuxprobe:~# kill -9 1340
```

### killall

killall 命令用于终止指定服务名称对应的所有进程，语法格式为“killall [参数] 服务名称”。

```bash
root@linuxprobe:~# pidof httpd
13581 13580 13579 13578 13577 13576
root@linuxprobe:~# killall httpd
root@linuxprobe:~# pidof httpd
root@linuxprobe:~# 
```

### uname

uname 命令用于查看系统内核版本与系统架构等信息，英文全称为 UNIX Name，语法格式为“uname [参数]”。
在使用 uname 命令时，一般要固定搭配-a 参数来完整地查看当前系统的内核名称、主机名、内核发行版本、节点名、编译时间、硬件名称、硬件平台、处理器类型以及操作系统名称等信息：
```bash
root@linuxprobe:~# uname -a
Linux linuxprobe.com 6.12.0-55.9.1.el10….x86_64 #1 SMP PREEMPT_DYNAMIC Mon Sep 23 04:19:12 EDT 2025 x86_64 GNU/Linux
```

### uptime
uptime 命令真的很棒，它可以显示当前系统时间、系统已运行时间、启用终端数量以及平均负载值等信息。平均负载值指的是系统在最近 1 分钟、5 分钟、15 分钟内的压力情况（下面加粗的信息部分），负载值越低越好：
```bash
root@linuxprobe:~# uptime
 09:55:09 up 22 min,  2 users,  load average: 0.06, 0.05, 0.06
```

### free

free 命令用于显示当前系统中内存的使用量信息，语法格式为“free [参数]”。
在使用 free 命令时，可以结合使用-h 参数以更人性化的方式输出当前内存的实时使用量信息。
```bash
root@linuxprobe:~# free -h
```


### who
who 命令用于查看当前登录主机的用户终端信息

|登录的用户名|终端设备|登录系统的时间|
|---|---|---|
|root|seat0|2025-05-18 09:36(login screen)|
|root|tty2|2025-05-18 09:36(tty2)|

| 终端标识              | 类型             | 说明                                     |
| ----------------- | -------------- | -------------------------------------- |
| **ttyN** (如 tty2) | **物理终端/虚拟控制台** | 本地登录的文本界面（按 Ctrl+Alt+F2~F6 进入）         |
| **seat0**         | **图形会话座位**     | 本地图形界面登录（GNOME/KDE 等桌面环境）              |
| **pts/N**         | **伪终端**        | SSH 远程登录或终端模拟器（xterm、gnome-terminal 等） |

### ping

ping 命令用于测试主机之间的网络连通性，语法格式为“ping [参数] 主机地址”。

|参数|作用|
|---|---|
|-c|总共发送次数|
|-i|每次间隔时间（秒）|
|-W|最长等待时间（秒）|

### find

find 命令用于按照指定条件查找文件及目录，语法格式为“find [查找范围] 寻找条件”

| 参数                | 作用                                                |
| ----------------- | ------------------------------------------------- |
| **-name**         | 匹配名称                                              |
| -perm             | 匹配权限（+mode 为完全匹配，-mode 为包含即可）                     |
| -user             | 匹配所有者                                             |
| -group            | 匹配所属组                                             |
| -mtime -n +n      | 匹配修改内容的时间（-n 指 n 天以内，+n 指 n 天以前）                  |
| -atime -n +n      | 匹配访问文件的时间（-n 指 n 天以内，+n 指 n 天以前）                  |
| -ctime -n +n      | 匹配修改文件权限的时间（-n 指 n 天以内，+n 指 n 天以前）                |
| -nouser           | 匹配无所有者的文件                                         |
| -nogroup          | 匹配无所属组的文件                                         |
| -newer f1 !f2     | 匹配比文件 f1 新但比 f2 旧的文件                              |
| -type b/d/c/p/l/f | 匹配文件类型（后面的字母依次表示块设备、目录、字符设备、管道、链接 文件、普通文件）        |
| **-size**         | 匹配文件的大小（+50k 为查找超过 50KB 的文件，而-50k 为查找小于 50KB 的文件） |
| -prune            | 忽略某个目录                                            |
| -exec …… ;        | 后面可跟用于进一步处理搜索结果的命令（下文会有演示）                        |

### locate

locate 命令用于按照名称快速搜索文件所对应的位置，语法格式为“locate [参数] 对象”。
第一次使用 locate 命令之前，记得先执行 updatedb 命令生成索引数据库，然后再进行查找：

第一次使用 locate 命令之前，记得先执行 updatedb 命令生成索引数据库，然后再进行查找：
```bash
root@linuxprobe:~# updatedb 
root@linuxprobe:~# ls -l /var/lib/plocate/plocate.db
-rw-r-----. 1 root plocate 2527288 May 18 10:25 /var/lib/plocate/plocate.db
```

```bash
root@linuxprobe:~# locate whereis
/usr/bin/whereis
/usr/share/bash-completion/completions/whereis
/usr/share/man/man1/whereis.1.gz
```

### whereis

whereis 命令用于按照名称快速搜索二进制程序（命令）、源代码以及帮助文件所对应的位置，语法格式为“whereis 命令名称”。

```bash
root@linuxprobe:~# whereis ls
ls: /usr/bin/ls /usr/share/man/man1/ls.1.gz
root@linuxprobe:~# whereis pwd
pwd: /usr/bin/pwd /usr/share/man/man1/pwd.1.gz
```

### which

which 命令用于按照指定名称快速搜索二进制程序（命令）对应的位置，语法格式为“which 命令名称”。

```bash
root@linuxprobe:~# which locate
/usr/bin/locate
root@linuxprobe:~# which whereis
/usr/bin/whereis
```

### tr
tr 命令用于替换文本内容中的字符，英文全称为 translate，语法格式为“tr 原始字符目标字符”。
```bash
root@linuxprobe:~# cat anaconda-ks.cfg | tr 'a-z' 'A-Z'
# GENERATED BY ANACONDA 40.22.3.12
# GENERATED BY PYKICKSTART V3.52.5
#VERSION=RHEL10
# USE GRAPHICAL INSTALL
GRAPHICAL

%ADDON COM_REDHAT_KDUMP --DISABLE

%END

# KEYBOARD LAYOUTS
KEYBOARD --VCKEYMAP=US --XLAYOUTS='US'
# SYSTEM LANGUAGE
LANG EN_US.UTF-8
………………省略部分输出信息………………
```

### wc

wc 命令用于统计指定文本文件的行数、字数或字节数，英文全称为word count，语法格式为“wc [参数] 文件名”。

|参数|作用|
|---|---|
|-l|只显示行数|
|-w|只显示单词数|
|-c|只显示字节数|
```bash
root@linuxprobe:~# wc -l /etc/passwd
38 /etc/passwd
```

### stat

stat 命令用于查看文件的具体存储细节和时间等信息，英文全称为status，语法格式为“stat 文件名”。
Linux 系统中的文件包含 3 种时间状态，分别是**Access Time（内容最后一次被访问的时间，简称为 Atime），Modify Time（内容最后一次被修改的时间，简称为 Mtime）以及 Change Time（文件属性最后一次被修改的时间，简称为 Ctime）**。

```bash
root@linuxprobe:~# stat anaconda-ks.cfg
  File: anaconda-ks.cfg
  Size: 1019      	Blocks: 8          IO Block: 4096   regular file
Device: 253,0	Inode: 33826925    Links: 1
Access: (0600/-rw-------)  Uid: (    0/    root)   Gid: (    0/    root)
Context: system_u:object_r:admin_home_t:s0
Access: 2025-05-18 10:05:30.651095368 +0800
Modify: 2025-03-08 20:06:44.282103236 +0800
Change: 2025-03-08 20:06:44.282103236 +0800
 Birth: 2025-03-08 20:06:44.235103234 +0800
```

### grep

grep 命令用于根据指定的模式（如字符串、正则表达式等）来搜索和提取对应的文本内容，英文全称为 Global Regular Expression Print，语法格式为“grep [参数] 模式 文件名”。

| 参数     | 作用                            |
| ------ | ----------------------------- |
| -b     | 将可执行文件（binary）当作文本文件（text）来搜索 |
| -c     | 仅显示找到的行数                      |
| -i     | 忽略大小写                         |
| **-n** | **显示行号**                      |
| **-v** | **反向选择—仅列出没有“关键词”的行**         |
### cut
cut 命令用于按“列”提取文本内容，语法格式为“cut [参数] 文件名”。
按“列”搜索，不仅要使用-f 参数设置需要查看的列数，还需要使用-d 参数设置间隔符号。
```bash
root@linuxprobe:~# cut -d : -f 1 /etc/passwd
root
bin
daemon
adm
lp
sync
shutdown
halt
mail
operator
games
ftp
………………省略部分输出信息………………
```

### diff
diff 命令用于比较多个文件之间内容的差异，英文全称为 difference，语法格式为“diff [参数] 文件名 A 文件名 B”。

可以使用--brief 参数确认两个文件是否相同，还可以使用-c 参数详细比较多个文件的差异之处。
```bash
root@linuxprobe:~# cat diff_A.txt
Welcome to linuxprobe.com
Red Hat certified
Free Linux Lessons
Professional guidance
Linux Course
root@linuxprobe:~# cat diff_B.txt
Welcome tooo linuxprobe.com

Red Hat certified
Free Linux LeSSonS
////////.....////////
Professional guidance
Linux Course

root@linuxprobe:~# diff --brief diff_A.txt diff_B.txt
Files diff_A.txt and diff_B.txt differ

root@linuxprobe:~# diff -c diff_A.txt diff_B.txt
*** diff_A.txt	2025-05-18 10:34:30.829180338 +0800
--- diff_B.txt	2025-05-18 10:34:40.334180802 +0800
***************
*** 1,5 ****
! Welcome to linuxprobe.com
  Red Hat certified
! Free Linux Lessons
  Professional guidance
  Linux Course
--- 1,7 ----
! Welcome tooo linuxprobe.com
! 
  Red Hat certified
! Free Linux LeSSonS
! ////////.....////////
  Professional guidance
  Linux Course
```

### uniq

uniq 命令用于去除文本中连续的重复行，英文全称为unique，语法格式为“uniq [参数] 文件名”。

### sort
sort 命令用于对文本内容进行排序，语法格式为“sort [参数] 文件名”。

| 参数  | 作用      |
| --- | ------- |
| -f  | 忽略大小写   |
| -b  | 忽略缩进与空格 |
| -n  | 以数值型排序  |
| -r  | 反向排序    |
| -u  | 去除重复行   |
| -t  | 指定间隔符   |
| -k  | 设置字段范围  |
如果想以第 3 个字段中的数字作为排序依据，那么可以用-t 参数指定间隔符，用-k 参数指定第几列，用-n 参数进行数字排序来搞定：
```bash
root@linuxprobe:~# sort -t : -k 3 -n user.txt 
rpc:x:32:32:Rpcbind Daemon
tss:x:59:59:Account used by the trousers package to sandbox the tcsd daemon
qemu:x:107:107:qemu user
usbmuxd:x:113:113:usbmuxd user
pulse:x:171:171:PulseAudio System Daemon
rtkit:x:172:172:RealtimeKit
gluster:x:995:990:GlusterFS daemons
unbound:x:996:991:Unbound DNS resolver
geoclue:x:997:995:User for geoclue
polkitd:x:998:996:User for polkitd
```

### touch

touch 命令用于创建空白文件或设置文件的时间，语法格式为“touch [参数] 文件名”。

|参数|作用|
|---|---|
|-a|仅修改“访问时间”（Atime）|
|-m|仅修改“修改时间”（Mtime）|
|-d|同时修改 Atime 与 Mtime|
```bash
root@linuxprobe:~# ls -l anaconda-ks.cfg
-rw-------. 1 root root 1019 Mar  8 20:06 anaconda-ks.cfg
root@linuxprobe:~# echo "Visit LinuxProbe.com to learn linux" >> anaconda-ks.cfg
root@linuxprobe:~# ls -l anaconda-ks.cfg
-rw-------. 1 root root 1062 May 18 10:38 anaconda-ks.cfg

root@linuxprobe:~# touch -d "2025-05-18 15:44" anaconda-ks.cfg 
root@linuxprobe:~# ls -l anaconda-ks.cfg 
-rw-------. 1 root root 1062 May 18  15:44 anaconda-ks.cfg
```

### mkdir

mkdir 命令用于创建空白的目录
mkdir 命令还可以结合-p 参数递归创建出具有嵌套层叠关系的文件目录：
```bash
root@linuxprobe:~# mkdir linuxprobe
root@linuxprobe:~# cd linuxprobe
root@linuxprobe:~/linuxprobe# mkdir -p a/b/c/d/e
root@linuxprobe:~/linuxprobe# cd a
root@linuxprobe:~/linuxprobe/a# cd b
root@linuxprobe:~/linuxprobe/a/b#
```

### cp
cp 命令用于复制文件或目录，英文全称为 copy，语法格式为“cp [参数] 源文件名目标文件名”。

|参数|作用|
|---|---|
|-p|保留原始文件的属性|
|-d|若对象为符号链接，则保留符号链接本身，而不是复制其指向的文件|
|-r|递归持续复制（用于目录）|
|-i|若目标文件存在，则询问是否覆盖|
|-a|相当于-pdr（p、d、r 为上述参数）|
### mv
mv 命令用于剪切或重命名文件，英文全称为 move，语法格式为“mv [参数] 源文件名目标文件名”。

### rm
rm 命令用于删除文件或目录，英文全称为 remove，语法格式为“rm [参数] 文件名称”。

| 参数  | 作用    |
| --- | ----- |
| -f  | 强制执行  |
| -i  | 删除前询问 |
| -r  | 删除目录  |
| -v  | 显示过程  |
### dd
dd 命令用于按照指定大小和个数的数据块复制文件或转换文件，语法格式为“dd if=参数值 of=参数值 count=参数值 bs=参数值”。

|参数|作用|
|---|---|
|if|输入的文件名称|
|of|输出的文件名称|
|bs|设置每个“块”的大小|
|count|设置要复制的“块”的个数|
### file
file 命令用于查看文件的类型，语法格式为“file 文件名”

### tar

tar 命令用于对文件进行打包压缩或解压，语法格式为“tar [参数] [文件或目录名]”。

|参数|作用|
|---|---|
|-c|创建压缩文件|
|-x|解开压缩文件|
|-t|查看压缩包内有哪些文件|
|-z|用 gzip 格式进行压缩或解压|
|-j|用 bzip2 格式进行压缩或解压|
|-v|显示压缩或解压的过程|
|-f|目标文件名|
|-p|保留原始权限与属性|
|-P|保留绝对路径|
|-C|指定解压到的目标目录|
-c 参数用于创建压缩文件，-x 参数用于解压文件，因此这两个参数不能同时使用。其次，-z 参数指定使用 gzip 格式压缩或解压文件，-j 参数指定使用 bzip2 格式压缩或解压文件。用户使用时则是根据文件的后缀来决定应使用何种格式的参数进行解压。在执行某些压缩或解压操作时，可能需要花费数个小时，如果屏幕一直没有输出，一方面我们不好判断打包的进度情况，另一方面也会怀疑系统宕机了，因此非常推荐使用-v 参数向用户不断显示压缩或解压的过程。-C 参数用于指定要解压到哪个指定的目录。**-f 参数特别重要， 必须紧跟目标文件名**，其他参数的位置没有强制要求。

一般使用“tar –czvf 压缩包名称.tar.gz 要打包的目录”命令把指定的文件进行打包压缩；相应的解压命令为“tar –xzvf 压缩包名称.tar.gz”。