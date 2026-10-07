---
kind: issue
title: "指纹自动禁言不填写原因"
type: ff
status: open
created: 2026-10-07
---

# 指纹自动禁言不填写原因

按用户要求，指纹命中仍自动禁言，但不再填写可见的禁言原因；后台指纹关联查询、禁言期限、保留帖子和禁言操作记录不变。通用禁言通知仍保留；不删除已有禁言记录中的旧原因。

- 改动：`app/controllers/fingerprint_controller.rb` 移除 `reason` 参数；`config/locales/server.en.yml` 删除未使用的指纹禁言原因文案。
- 回归测试：`spec/requests/fingerprint_controller_spec.rb` 增加命中后无原因且保留帖子、不命中不禁言、仅隐藏指纹不禁言、已有禁言原因不被覆盖四种场景。
- 验证：`git diff --check` 通过；PyYAML 解析语言文件通过；检索确认已无旧原因文案引用。RSpec 未运行成功：当前环境缺少 Ruby/Bundler，执行测试报 `bundle: 未找到命令`（退出码 127）；待在 Discourse 测试环境回归或用户确认实际效果。
- codestable：无既有规格需要回写；仅新增本次快改记录，验证待完成。
