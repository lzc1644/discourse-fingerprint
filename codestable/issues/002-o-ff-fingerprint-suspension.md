---
kind: issue
title: "按指纹或 Cookie 自动封禁账号"
type: ff
status: open
created: 2026-10-29
---

# 按指纹或 Cookie 自动封禁账号

保留原有禁言，新增独立封禁规则：账号下次上报命中指纹或插件 `fp` Cookie 时，由系统封禁 1000 年并退出登录，保留帖子和处罚记录，不填写原因；封禁优先于禁言。移除规则只停止后续自动封禁，不解除已有账号处罚。实现与验证完成，待用户验收。

- 改动：新增 `flagged_fingerprints.suspended` 数据库迁移；扩展后台规则接口、上报处理及序列化；三个指纹列表增加封禁／移除规则按钮、二次确认和错误提示；补齐单用户报告的规则状态；更新 `README.md`。
- 验证：隔离 Discourse 测试库迁移成功；请求与插件测试 **19 个通过**（指纹、Cookie、退出登录、权限、优先级、保留原禁言、移除规则及报告状态）；新增 QUnit 浏览器用例 **2 个通过、10 个断言通过**；真实 Rails／浏览器完成添加规则、刷新持久化、单用户报告和移除规则，并检查截图；Ruby、JS、模板、CSS 和格式检查通过，`git diff --check` 通过。
- 复现：Discourse 根目录运行 `LOAD_PLUGINS=1 bin/rspec plugins/discourse-fingerprint/spec/requests plugins/discourse-fingerprint/spec/plugin_spec.rb`；浏览器用例为 `test/javascripts/acceptance/fingerprint-suspension-test.js`。
- 使用：更新安装时须执行正常 Discourse 插件重建／数据库迁移；规则沿用原有的上报时触发方式，不会立即批量处理历史关联账号。相似浏览器或共用设备可能误匹配，启用前须核对。
- codestable：无既有 Project／Epic Spec 需要同步；仅新增本次快改记录。未部署。
