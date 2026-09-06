# 学习记录规则

`progress.json` 是唯一结构化进度来源；课程任务定义在 `curriculum.json`，不要重复修改课程来假装完成。

## 任务与周状态

- pending：尚无完成证据。
- in_progress：已开始，仍有具体子任务未完成。
- learner_reported：用户表示已完成，尚未检查所需证据。
- verified：按课程验收要求检查后通过。evidence 数组记录文件、测试输出、实验报告或解释的会话位置。
- skipped_by_request：用户选择跳过，保留原因与后续复习项。

每项任务已有稳定ID，例如 W01-T01。task.evidence 元素应包含 kind、location、summary、checked_at，kind 可为 code、output、experiment、explanation 或 user_report。明确区分用户自述、助手执行和学习者操作。actual_minutes 未获知时为 null，不使用对话经过时间代替。

周 acceptance.status 使用 pending、in_progress、passed 或 skipped_by_request；只有相关产出及解释通过时才写 passed。用户更改学习路线可以调整 current_week 并写入调整原因，不应把跳过的周写成 passed。next_step 保留足够具体的恢复点。

## 写入与恢复

1. 更新前重新读取现有文件，保留不属于本轮修改的字段和历史记录。若文件已变化则合并，避免覆盖其他会话结果。
2. 写入前保存一份 `progress.previous.json`，随后以同目录临时文件写入合法UTF-8 JSON，并用原子替换更新原文件。不要通过字符串拼接构造shell命令；用文件编辑工具或安全脚本操作。
3. 会话记录包含 session_id、本地日期、关联周和任务、时间预算、实际分钟、当天安排、实际结果、证据、知识缺口及 next_step。
4. 同一session只登记一次；再次更新同一记录，不重复累计时长。关闭会话时更新 session.actual_minutes；total_actual_minutes 由已知的会话分钟数求和。未知的时长保持未知。
5. 任务报告和下一步更新完成后，重新读回进度确认JSON有效。用户没有回答或只收到计划时，保留pending或in_progress，不升为verified。
6. 日期使用 Asia/Shanghai。profile中的每周10小时和默认每次60分钟是可修改的计划值，不是用户已实际投入的时间。

## 会话记录模板

```markdown
# 学习记录 YYYY-MM-DD

- Session ID：YYYY-MM-DD-01
- 当前周与任务：
- 计划分钟：
- 实际分钟：未知
- 状态：进行中

## 当天目标与安排

## 实际完成和证据

分别说明学习者完成、助手演示和待验收部分。

## 验收反馈

## 知识缺口与复习

## 下次起点
```
