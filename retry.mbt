// Retry strategies: fixed interval, exponential backoff, exponential with jitter

pub enum RetryStrategy {
  Fixed(Int)
  Exponential(Int, Double, Int)
  ExponentialWithJitter(Int, Double, Int)
}

pub struct RetryConfig {
  max_attempts: Int
  strategy: RetryStrategy
}

pub fn RetryConfig::new(max_attempts: Int, strategy: RetryStrategy) -> RetryConfig {
  { max_attempts: max_attempts, strategy: strategy }
}

pub fn RetryConfig::default() -> RetryConfig {
  { max_attempts: 3, strategy: Fixed(100) }
}

// Helper constructors for retry strategies (enum variants cannot be constructed cross-package)
pub fn RetryStrategy::fixed(delay: Int) -> RetryStrategy {
  Fixed(delay)
}

pub fn RetryStrategy::exponential(initial: Int, mult: Double, max: Int) -> RetryStrategy {
  Exponential(initial, mult, max)
}

pub fn RetryStrategy::exponential_with_jitter(initial: Int, mult: Double, max: Int) -> RetryStrategy {
  ExponentialWithJitter(initial, mult, max)
}

// Simple pseudo-random in [0, 1), no external dependency
fn pseudo_random(seed: Int) -> Double {
  let s = (seed * 1103515245 + 12345) & 2147483647
  s.to_double() / 2147483647.0
}

pub fn RetryStrategy::delay(self: RetryStrategy, attempt: Int) -> Int {
  match self {
    Fixed(d) => d
    Exponential(initial, mult, max) => {
      let d = initial.to_double() * @math.pow(mult, attempt.to_double())
      let d_int = d.to_int()
      if d_int > max { max } else { d_int }
    }
    ExponentialWithJitter(initial, mult, max) => {
      let d = initial.to_double() * @math.pow(mult, attempt.to_double())
      let jitter = 0.5 + pseudo_random(attempt + 1) * 1.0
      let d_jittered = d * jitter
      let d_int = d_jittered.to_int()
      if d_int > max { max } else { d_int }
    }
  }
}

// Retry without sleeping. Returns Some(result) on success, None on exhaustion.
pub fn[T] retry(config: RetryConfig, f: () -> Option[T]) -> Option[T] {
  let mut attempt = 0
  while attempt < config.max_attempts {
    let result = f()
    match result {
      Some(_) => return result
      None => {
        attempt = attempt + 1
      }
    }
  }
  None
}

// Retry with a sleep callback. The callback receives the delay in milliseconds.
pub fn[T] retry_with_sleep(config: RetryConfig, sleep: (Int) -> Unit, f: () -> Option[T]) -> Option[T] {
  let mut attempt = 0
  while attempt < config.max_attempts {
    let result = f()
    match result {
      Some(_) => return result
      None => {
        attempt = attempt + 1
        if attempt < config.max_attempts {
          let delay = config.strategy.delay(attempt)
          sleep(delay)
        }
      }
    }
  }
  None
}

// Compute all retry delays for a given config (useful for testing and logging)
pub fn RetryConfig::all_delays(self: RetryConfig) -> Array[Int] {
  let delays : Array[Int] = []
  let mut i = 1
  while i < self.max_attempts {
    delays.push(self.strategy.delay(i))
    i = i + 1
  }
  delays
}
