/// Unit tests for mb-retry. Run with: moon test

test "fixed retry strategy delay" {
  let s = @mb_retry.RetryStrategy::fixed(100)
  @test.assert_eq(s.delay(1), 100)
  @test.assert_eq(s.delay(5), 100)
}

test "exponential backoff delay" {
  let s = @mb_retry.RetryStrategy::exponential(100, 2.0, 10000)
  @test.assert_eq(s.delay(1), 200)
  @test.assert_eq(s.delay(2), 400)
  @test.assert_eq(s.delay(3), 800)
}

test "exponential backoff caps at max" {
  let s = @mb_retry.RetryStrategy::exponential(100, 2.0, 500)
  @test.assert_eq(s.delay(1), 200)
  @test.assert_eq(s.delay(2), 400)
  @test.assert_eq(s.delay(3), 500)
  @test.assert_eq(s.delay(10), 500)
}

test "retry succeeds on first attempt" {
  let config = @mb_retry.RetryConfig::new(3, @mb_retry.RetryStrategy::fixed(100))
  let mut calls = 0
  let result = @mb_retry.retry(config, fn() {
    calls = calls + 1
    Some(42)
  })
  @test.assert_eq(result.is_some(), true)
  @test.assert_eq(result.unwrap(), 42)
  @test.assert_eq(calls, 1)
}

test "retry succeeds after failures" {
  let config = @mb_retry.RetryConfig::new(5, @mb_retry.RetryStrategy::fixed(100))
  let mut calls = 0
  let result = @mb_retry.retry(config, fn() {
    calls = calls + 1
    if calls < 3 { None } else { Some(99) }
  })
  @test.assert_eq(result.is_some(), true)
  @test.assert_eq(result.unwrap(), 99)
  @test.assert_eq(calls, 3)
}

test "retry exhausts max attempts" {
  let config = @mb_retry.RetryConfig::new(3, @mb_retry.RetryStrategy::fixed(100))
  let mut calls = 0
  let result = @mb_retry.retry(config, fn() {
    calls = calls + 1
    None
  })
  @test.assert_eq(result.is_none(), true)
  @test.assert_eq(calls, 3)
}

test "circuit breaker starts closed and allows" {
  let cb = @mb_retry.CircuitBreaker::new(3, 10000, 2)
  cb.set_time(0)
  @test.assert_eq(cb.allow(), true)
}

test "circuit breaker opens after threshold failures" {
  let cb = @mb_retry.CircuitBreaker::new(3, 10000, 2)
  cb.set_time(0)
  cb.on_failure()
  cb.on_failure()
  @test.assert_eq(cb.allow(), true)
  cb.on_failure()
  @test.assert_eq(cb.allow(), false)
}

test "circuit breaker half-open after recovery timeout" {
  let cb = @mb_retry.CircuitBreaker::new(2, 5000, 2)
  cb.set_time(0)
  cb.on_failure()
  cb.on_failure()
  @test.assert_eq(cb.allow(), false)
  cb.set_time(6000)
  @test.assert_eq(cb.allow(), true)
}

test "circuit breaker closes after half-open successes" {
  let cb = @mb_retry.CircuitBreaker::new(2, 5000, 2)
  cb.set_time(0)
  cb.on_failure()
  cb.on_failure()
  cb.set_time(6000)
  let _ = cb.allow()
  cb.on_success()
  let _ = cb.allow()
  cb.on_success()
  @test.assert_eq(cb.allow(), true)
}

test "token bucket allows up to capacity" {
  let tb = @mb_retry.TokenBucket::new(3, 1.0)
  tb.set_time(0)
  @test.assert_eq(tb.allow(), true)
  @test.assert_eq(tb.allow(), true)
  @test.assert_eq(tb.allow(), true)
  @test.assert_eq(tb.allow(), false)
}

test "token bucket refills over time" {
  let tb = @mb_retry.TokenBucket::new(2, 1000.0)
  tb.set_time(0)
  @test.assert_eq(tb.allow(), true)
  @test.assert_eq(tb.allow(), true)
  @test.assert_eq(tb.allow(), false)
  tb.set_time(10)
  @test.assert_eq(tb.allow(), true)
}

test "leaky bucket rejects when full" {
  let lb = @mb_retry.LeakyBucket::new(2, 1.0)
  lb.set_time(0)
  @test.assert_eq(lb.allow(), true)
  @test.assert_eq(lb.allow(), true)
  @test.assert_eq(lb.allow(), false)
}

test "sliding window rejects over limit" {
  let sw = @mb_retry.SlidingWindow::new(1000, 2)
  sw.set_time(0)
  @test.assert_eq(sw.allow(), true)
  @test.assert_eq(sw.allow(), true)
  @test.assert_eq(sw.allow(), false)
}

test "sliding window evicts old requests" {
  let sw = @mb_retry.SlidingWindow::new(1000, 2)
  sw.set_time(0)
  @test.assert_eq(sw.allow(), true)
  @test.assert_eq(sw.allow(), true)
  sw.set_time(1500)
  @test.assert_eq(sw.allow(), true)
}
