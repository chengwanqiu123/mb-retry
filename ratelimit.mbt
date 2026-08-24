// Rate limiting algorithms: token bucket, leaky bucket, sliding window

pub struct TokenBucket {
  capacity: Int
  refill_rate: Double
  mut tokens: Double
  mut last_refill_ms: Int
  mut current_time_ms: Int
}

pub fn TokenBucket::new(capacity: Int, refill_per_second: Double) -> TokenBucket {
  {
    capacity: capacity,
    refill_rate: refill_per_second / 1000.0,
    tokens: capacity.to_double(),
    last_refill_ms: 0,
    current_time_ms: 0,
  }
}

pub fn TokenBucket::set_time(self: TokenBucket, ms: Int) -> Unit {
  self.current_time_ms = ms
}

fn TokenBucket::refill(self: TokenBucket) -> Unit {
  let elapsed = (self.current_time_ms - self.last_refill_ms).to_double()
  let new_tokens = elapsed * self.refill_rate
  self.tokens = self.tokens + new_tokens
  if self.tokens > self.capacity.to_double() {
    self.tokens = self.capacity.to_double()
  }
  self.last_refill_ms = self.current_time_ms
}

pub fn TokenBucket::allow(self: TokenBucket) -> Bool {
  self.allow_n(1)
}

pub fn TokenBucket::allow_n(self: TokenBucket, n: Int) -> Bool {
  self.refill()
  if self.tokens >= n.to_double() {
    self.tokens = self.tokens - n.to_double()
    true
  } else {
    false
  }
}

pub fn TokenBucket::tokens(self: TokenBucket) -> Double {
  self.refill()
  self.tokens
}

pub struct LeakyBucket {
  capacity: Int
  leak_rate: Double
  mut current: Double
  mut last_leak_ms: Int
  mut current_time_ms: Int
}

pub fn LeakyBucket::new(capacity: Int, leak_per_second: Double) -> LeakyBucket {
  {
    capacity: capacity,
    leak_rate: leak_per_second / 1000.0,
    current: 0.0,
    last_leak_ms: 0,
    current_time_ms: 0,
  }
}

pub fn LeakyBucket::set_time(self: LeakyBucket, ms: Int) -> Unit {
  self.current_time_ms = ms
}

fn LeakyBucket::leak(self: LeakyBucket) -> Unit {
  let elapsed = (self.current_time_ms - self.last_leak_ms).to_double()
  let leaked = elapsed * self.leak_rate
  self.current = self.current - leaked
  if self.current < 0.0 {
    self.current = 0.0
  }
  self.last_leak_ms = self.current_time_ms
}

pub fn LeakyBucket::allow(self: LeakyBucket) -> Bool {
  self.leak()
  if self.current < self.capacity.to_double() {
    self.current = self.current + 1.0
    true
  } else {
    false
  }
}

pub fn LeakyBucket::size(self: LeakyBucket) -> Double {
  self.leak()
  self.current
}

pub struct SlidingWindow {
  window_size_ms: Int
  max_requests: Int
  mut requests: Array[Int]
  mut current_time_ms: Int
}

pub fn SlidingWindow::new(window_size_ms: Int, max_requests: Int) -> SlidingWindow {
  {
    window_size_ms: window_size_ms,
    max_requests: max_requests,
    requests: [],
    current_time_ms: 0,
  }
}

pub fn SlidingWindow::set_time(self: SlidingWindow, ms: Int) -> Unit {
  self.current_time_ms = ms
}

fn SlidingWindow::evict(self: SlidingWindow) -> Unit {
  let threshold = self.current_time_ms - self.window_size_ms
  let new_requests : Array[Int] = []
  let mut i = 0
  while i < self.requests.length() {
    if self.requests[i] > threshold {
      new_requests.push(self.requests[i])
    }
    i = i + 1
  }
  self.requests = new_requests
}

pub fn SlidingWindow::allow(self: SlidingWindow) -> Bool {
  self.evict()
  if self.requests.length() < self.max_requests {
    self.requests.push(self.current_time_ms)
    true
  } else {
    false
  }
}

pub fn SlidingWindow::count(self: SlidingWindow) -> Int {
  self.evict()
  self.requests.length()
}
