# 2026-09-07 WSL 启动诊断摘要

症状：重启 Windows 后，Ubuntu WSL2 启动仍报 Wsl/Service/E_UNEXPECTED；hns、vmcompute、WslService 均在运行。

学习者以管理员身份运行 diagnose-wsl.ps1，助手解析本机采集日志。原始来源为 logs-20260907-004538-907/lxss-readable.txt 第789–807行；原始日志仅留本机，以下摘录供仓库迁移后复核：

```text
Found tmpfs on /sys/fs/cgroup/, assuming legacy hierarchy.
Detected cgroup v1 hierarchy at /sys/fs/cgroup/, which is no longer supported by current version of systemd.
Detected unsupported legacy cgroup hierarchy, refusing execution.
Exiting PID 1...
Expected message 3, but socket WslCorePort was closed
```

当时 systemd 259.5 因不支持 cgroup v1 而退出 PID 1，随后 WSL 通道关闭。助手在原电脑用户目录 .wslconfig 配置统一 cgroup v2，并重启 WSL，配置副本见 [wslconfig-applied.ini](wslconfig-applied.ini)。

恢复后的助手检查见 [environment-verified.txt](environment-verified.txt)：Ubuntu 26.04.1 LTS、WSL 2.4.13.0 / 内核 5.15.167.4-1、Python 3.14.4、cgroup2fs、PID 1 为 systemd、系统 running、失败服务数0；Linux 内识别 RTX 4070、驱动595.79、显存12282 MiB。学习者随后独立执行 wsl -d Ubuntu、pwd、whoami、python3 --version 成功，证据保存在 [当日会话](../../sessions/2026-09-07-01.md)。

以上是本机历史诊断与已验证修复，不是所有 E_UNEXPECTED 的通用原因。早期发现的 Sangfor Winsock 模块未被证实是本次故障原因。换电脑应先检查实际报错及环境，保留已有 .wslconfig 设置，不自动套用历史配置。
