// Circuit breaker: Closed -> Open -> HalfOpen state machine

pub enum CircuitState {
  Closed
  Open
  HalfOpen
}

pub struct CircuitBreaker {
  failure_threshold: Int
  recovery_timeout_ms: Int
  half_open_max_calls: Int
  mut state: CircuitState
  mut failure_count: Int
  mut opened_at_ms: Int
  mut half_open_success: Int
  mut half_open_failure: Int
  mut current_time_ms: Int
}

pub fn CircuitBreaker::new(failure_threshold: Int, recovery_timeout_ms: Int, half_open_max_calls: Int) -> CircuitBreaker {
  {
    failure_threshold: failure_threshold,
    recovery_timeout_ms: recovery_timeout_ms,
    half_open_max_calls: half_open_max_calls,
    state: Closed,
    failure_count: 0,
    opened_at_ms: 0,
    half_open_success: 0,
    half_open_failure: 0,
    current_time_ms: 0,
  }
}

pub fn CircuitBreaker::default() -> CircuitBreaker {
  CircuitBreaker::new(5, 30000, 3)
}

pub fn CircuitBreaker::set_time(self: CircuitBreaker, ms: Int) -> Unit {
  self.current_time_ms = ms
}

pub fn CircuitBreaker::state(self: CircuitBreaker) -> CircuitState {
  self.state
}

pub fn CircuitBreaker::allow(self: CircuitBreaker) -> Bool {
  match self.state {
    Closed => true
    Open => {
      if self.current_time_ms - self.opened_at_ms >= self.recovery_timeout_ms {
        self.state = HalfOpen
        self.half_open_success = 0
        self.half_open_failure = 0
        true
      } else {
        false
      }
    }
    HalfOpen => {
      let total = self.half_open_success + self.half_open_failure
      total < self.half_open_max_calls
    }
  }
}

pub fn CircuitBreaker::on_success(self: CircuitBreaker) -> Unit {
  match self.state {
    Closed => {
      self.failure_count = 0
    }
    HalfOpen => {
      self.half_open_success = self.half_open_success + 1
      if self.half_open_success >= self.half_open_max_calls {
        self.state = Closed
        self.failure_count = 0
      }
    }
    Open => ()
  }
}

pub fn CircuitBreaker::on_failure(self: CircuitBreaker) -> Unit {
  match self.state {
    Closed => {
      self.failure_count = self.failure_count + 1
      if self.failure_count >= self.failure_threshold {
        self.state = Open
        self.opened_at_ms = self.current_time_ms
      }
    }
    HalfOpen => {
      self.half_open_failure = self.half_open_failure + 1
      self.state = Open
      self.opened_at_ms = self.current_time_ms
    }
    Open => ()
  }
}

pub fn[T] CircuitBreaker::execute(self: CircuitBreaker, f: () -> Option[T]) -> Option[T] {
  if !self.allow() {
    return None
  }
  let result = f()
  match result {
    Some(_) => {
      self.on_success()
      result
    }
    None => {
      self.on_failure()
      None
    }
  }
}

pub fn CircuitBreaker::reset(self: CircuitBreaker) -> Unit {
  self.state = Closed
  self.failure_count = 0
  self.opened_at_ms = 0
  self.half_open_success = 0
  self.half_open_failure = 0
}
