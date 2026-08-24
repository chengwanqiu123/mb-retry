fn main() -> Unit {
  println("=== mb-retry Demo ===")
  println("")

  // Demo 1: Retry with exponential backoff
  println("--- Retry Demo ---")
  let strategy = @lib.RetryStrategy::exponential(100, 2.0, 5000)
  let retry_config = @lib.RetryConfig::new(5, strategy)
  let delays = retry_config.all_delays()
  let mut delay_str = ""
  let mut i = 0
  while i < delays.length() {
    delay_str = delay_str + "\{delays[i]} "
    i = i + 1
  }
  println("Exponential backoff delays (ms): \{delay_str}")

  let mut attempts = 0
  let result = @lib.retry(retry_config, fn() {
    attempts = attempts + 1
    if attempts < 3 { None } else { Some("success on attempt \{attempts}") }
  })
  match result {
    Some(msg) => println("Retry result: \{msg}")
    None => println("Retry exhausted")
  }
  println("")

  // Demo 2: Circuit breaker
  println("--- Circuit Breaker Demo ---")
  let cb = @lib.CircuitBreaker::new(3, 10000, 2)
  cb.set_time(0)
  println("Initial state: Closed, allow=\{cb.allow()}")
  cb.on_failure()
  cb.on_failure()
  println("After 2 failures: allow=\{cb.allow()}")
  cb.on_failure()
  println("After 3 failures: allow=\{cb.allow()} (circuit OPEN)")
  cb.set_time(15000)
  println("After 15s: allow=\{cb.allow()} (circuit HALF-OPEN)")
  cb.on_success()
  cb.on_success()
  println("After 2 half-open successes: allow=\{cb.allow()} (circuit CLOSED)")
  println("")

  // Demo 3: Token bucket rate limiter
  println("--- Token Bucket Demo ---")
  let tb = @lib.TokenBucket::new(3, 500.0)
  tb.set_time(0)
  println("Capacity=3, refill=500/s")
  let mut j = 0
  while j < 5 {
    println("  Request \{j}: allow=\{tb.allow()}, tokens=\{tb.tokens()}")
    j = j + 1
  }
  tb.set_time(10)
  println("After 10ms: allow=\{tb.allow()}")
  println("")

  // Demo 4: Combined resilience pipeline
  println("--- Combined Pipeline Demo ---")
  let pipeline = @lib.ResilienceConfig::new(
    @lib.RetryConfig::new(3, @lib.RetryStrategy::fixed(50)),
    @lib.CircuitBreaker::new(2, 5000, 2),
    @lib.TokenBucket::new(5, 100.0),
  )
  pipeline.set_time(0)
  let mut count = 0
  let pipeline_result = pipeline.execute(fn() {
    count = count + 1
    if count < 2 { None } else { Some(123) }
  })
  match pipeline_result {
    Some(v) => println("Pipeline result: success, value=\{v} (took \{count} attempts)")
    None => println("Pipeline result: failed")
  }

  println("")
  println("=== Demo complete ===")
}
