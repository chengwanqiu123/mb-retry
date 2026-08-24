# mb-retry — MoonBit 云原生弹性工具库

面向云原生应用的轻量级容错工具库，提供**重试策略**、**熔断器**和**限流算法**三大核心能力，可单独使用或组合成弹性管道。

## 功能特性

### 重试策略 (Retry)
- 固定间隔重试 (Fixed)
- 指数退避 (Exponential Backoff)
- 带抖动的指数退避 (Exponential with Jitter)
- 可配置最大重试次数
- 支持自定义 sleep 回调

### 熔断器 (Circuit Breaker)
- 经典三态状态机：Closed → Open → Half-Open
- 可配置失败阈值、恢复超时、半开最大请求数
- 自动状态转换与重置
- 支持外部时钟注入（便于测试）

### 限流算法 (Rate Limiting)
- 令牌桶 (Token Bucket) — 支持突发流量
- 漏桶 (Leaky Bucket) — 平滑输出速率
- 滑动窗口计数 (Sliding Window) — 精确时间窗口控制

### 弹性管道 (Resilience Pipeline)
- 组合限流 → 熔断 → 重试，一键配置
- 统一时间管理
- 可直接包装 `async/http` client

## 项目结构

```
mb-retry/
├── moon.mod              # 模块配置
├── moon.pkg              # 包配置
├── retry.mbt             # 重试策略
├── circuit.mbt           # 熔断器
├── ratelimit.mbt         # 限流算法（令牌桶/漏桶/滑动窗口）
├── middleware.mbt        # 弹性管道组合
├── mb_retry_test.mbt     # 单元测试
├── README.md
├── PROJECT_PROPOSAL.md   # 项目申报书
├── contributing.md       # 贡献指南
└── cmd/main/
    ├── moon.pkg
    └── main.mbt          # 可运行示例
```

## 快速开始

### 重试

```moonbit
let config = RetryConfig::new(3, Exponential(100, 2.0, 5000))
let result = retry(config, fn() : Option[String] {
  // your operation that may fail
  Some("ok")
})
```

### 熔断器

```moonbit
let cb = CircuitBreaker::new(5, 30000, 3)
cb.set_time(current_time_ms())
let result = cb.execute(fn() : Option[Response] {
  // call downstream service
  Some(response)
})
```

### 限流

```moonbit
let tb = TokenBucket::new(100, 10.0)  // capacity=100, refill=10/s
tb.set_time(current_time_ms())
if tb.allow() {
  // process request
}
```

### 组合管道

```moonbit
let pipeline = ResilienceConfig::new(
  RetryConfig::new(3, Fixed(50)),
  CircuitBreaker::new(5, 30000, 3),
  TokenBucket::new(100, 10.0),
)
pipeline.set_time(current_time_ms())
let result = pipeline.execute(fn() : Option[Response] {
  // your operation
  Some(response)
})
```

## 构建与测试

```bash
# 构建
moon build

# 运行测试
moon test

# 运行示例
moon run cmd/main
```

## 设计原则

- **纯计算，无外部依赖**：核心算法不依赖 IO，可在 Wasm 沙箱中运行
- **时间可注入**：所有时间相关组件支持外部时钟，便于测试
- **可组合**：三大能力可单独使用，也可通过管道组合
- **轻量高性能**：适合 Serverless 和边缘计算的资源受限环境

## 生态价值

- 填补 MoonBit 云原生服务治理空白
- 可直接包装官方 `async/http` client
- 与 mb-timeseries 等监控库形成"服务治理 + 可观测性"生态矩阵
- Wasm 体积小，适合 Serverless 冷启动场景

## License

MIT
