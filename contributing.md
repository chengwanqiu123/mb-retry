# 贡献指南

感谢你对 mb-retry 的兴趣！本文档描述了如何参与项目开发。

## 开发环境

- MoonBit 工具链（moon 0.1.20260807+）
- Git
- 任意文本编辑器 / VS Code（推荐安装 MoonBit 插件）

## 常用命令

```bash
# 构建项目
moon build

# 运行测试
moon test

# 运行示例
moon run cmd/main

# 格式化代码
moon fmt
```

## 编码规范

1. **模块划分**：每个核心能力独立文件（retry.mbt / circuit.mbt / ratelimit.mbt），组合逻辑放 middleware.mbt
2. **命名**：类型用 PascalCase，函数和变量用 snake_case，常量用 UPPER_SNAKE_CASE
3. **时间管理**：所有时间相关组件必须支持外部时钟注入（set_time 方法），不直接调用系统时钟 API
4. **错误处理**：使用 Option[T] 表示成功/失败，Some 为成功，None 为失败
5. **可变性**：仅在需要修改状态时使用 mut 字段，优先使用不可变数据
6. **注释**：所有公开 API 必须有文档注释，包含功能说明、参数说明和返回值说明

## 测试要求

1. 新增功能必须配套单元测试
2. 测试文件命名为 `*_test.mbt`，与源码同目录
3. 使用 `@test.assert_eq(a, b)` 进行断言
4. 测试应覆盖：正常路径、边界条件、错误路径
5. 时间相关测试必须使用 set_time 注入固定时间，不依赖真实时钟

## 提交规范

1. 提交信息格式：`<type>: <description>`
   - `feat`: 新功能
   - `fix`: 修复 bug
   - `docs`: 文档更新
   - `refactor`: 代码重构
   - `test`: 测试相关
   - `chore`: 构建/工具链相关
2. 示例：`feat: add sliding window rate limiter`
3. 每次提交应聚焦一个变更，避免混合多个不相关的修改

## 不接受的变更范围

- 引入外部运行时依赖（核心库必须保持纯计算、无外部依赖）
- 直接调用系统时钟 API（必须通过 set_time 注入）
- 与核心容错能力无关的功能（如 HTTP client 实现、服务发现等）
- 破坏现有 API 兼容性的修改（除非有充分理由并在 PR 中说明）

## 提问与讨论

- 提交 Issue：https://github.com/chengwanqiu123/mb-retry/issues
- 提交 PR：https://github.com/chengwanqiu123/mb-retry/pulls

再次感谢你的贡献！
