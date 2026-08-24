// Resilience pipeline: combines rate limiter, circuit breaker, and retry

pub struct ResilienceConfig {
  retry_config: RetryConfig
  circuit: CircuitBreaker
  rate_limiter: TokenBucket
}

pub fn ResilienceConfig::new(
  retry_config: RetryConfig,
  circuit: CircuitBreaker,
  rate_limiter: TokenBucket,
) -> ResilienceConfig {
  { retry_config: retry_config, circuit: circuit, rate_limiter: rate_limiter }
}

// Set current time for all time-dependent components
pub fn ResilienceConfig::set_time(self: ResilienceConfig, ms: Int) -> Unit {
  self.circuit.set_time(ms)
  self.rate_limiter.set_time(ms)
}

// Execute a function through the full resilience pipeline:
// 1. Rate limit check
// 2. Circuit breaker + retry
pub fn[T] ResilienceConfig::execute(self: ResilienceConfig, f: () -> Option[T]) -> Option[T] {
  if !self.rate_limiter.allow() {
    return None
  }
  let cb = self.circuit
  let retry_fn = fn() {
    cb.execute(f)
  }
  retry(self.retry_config, retry_fn)
}

// Execute with a sleep callback for retry delays
pub fn[T] ResilienceConfig::execute_with_sleep(
  self: ResilienceConfig,
  sleep: (Int) -> Unit,
  f: () -> Option[T],
) -> Option[T] {
  if !self.rate_limiter.allow() {
    return None
  }
  let cb = self.circuit
  let retry_fn = fn() {
    cb.execute(f)
  }
  retry_with_sleep(self.retry_config, sleep, retry_fn)
}
