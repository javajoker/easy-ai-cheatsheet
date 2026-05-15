---
name: java-concurrency
description: Use when writing or reviewing concurrent Java code — threads, virtual threads (Project Loom), `CompletableFuture`, `ExecutorService`, locks (`synchronized`, `ReentrantLock`), thread-safe collections, atomic types, structured concurrency, or `Thread.interrupt()` handling. Also use when diagnosing deadlocks, livelocks, or race conditions.
license: Apache-2.0
compatibility: Examples target Java 21+ (virtual threads, structured concurrency preview). Notes for 17 LTS.
metadata:
  sources: "Java Concurrency in Practice, JEP 444 (virtual threads), JEP 453 (structured concurrency)"
---

# Java Concurrency

## Don't Manage Threads Directly

Avoid `new Thread(...).start()` in application code. Use an `ExecutorService`:

```java
// Bad
new Thread(() -> doWork()).start();

// Good
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
  executor.submit(() -> doWork());
}
```

The executor manages the lifecycle, gives you `Future`/`CompletableFuture`
returns, and shuts down cleanly with try-with-resources (Java 19+).

---

## Virtual Threads (Java 21+)

Virtual threads (Project Loom) make thread-per-request cheap. Use them for
blocking I/O — they suspend on blocking calls without holding an OS thread.

```java
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
  List<Future<User>> futures = userIds.stream()
      .map(id -> exec.submit(() -> fetchUser(id)))
      .toList();
  // collect results...
}
```

For CPU-bound work, virtual threads bring no benefit — use a fixed pool
sized to CPU count:

```java
var cpuExec = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
```

Don't replace **every** `newFixedThreadPool` with virtual threads. The rule:

- **Blocking I/O** (DB calls, HTTP, file): virtual threads.
- **CPU-bound** (encoding, parsing, computation): fixed pool sized to cores.

---

## `CompletableFuture` for Async Composition

When you need to compose async operations:

```java
CompletableFuture<User> userF = fetchUserAsync(id);
CompletableFuture<List<Order>> ordersF = fetchOrdersAsync(id);

CompletableFuture<Dashboard> dashboardF =
    userF.thenCombine(ordersF, (user, orders) -> new Dashboard(user, orders));

Dashboard d = dashboardF.join();          // block; or use thenAccept for non-blocking
```

`.join()` blocks the caller — fine in `main` or a request handler. Don't
`.join()` deep inside a reactive pipeline.

For "all of" and "any of":

```java
CompletableFuture.allOf(f1, f2, f3).join();   // wait for all
CompletableFuture.anyOf(f1, f2, f3).join();   // wait for first
```

Errors: `.exceptionally(t -> fallback)` or `.handle((value, ex) -> ...)`.

With virtual threads, often you don't need `CompletableFuture` — just block
in a virtual thread. Reserve `CompletableFuture` for genuine composition.

---

## Structured Concurrency (Java 21 preview)

`StructuredTaskScope` ties subtasks to a parent scope; the parent doesn't
return until all subtasks complete (or fail, depending on the policy):

```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
  Supplier<User> user = scope.fork(() -> fetchUser(id));
  Supplier<List<Order>> orders = scope.fork(() -> fetchOrders(id));

  scope.join();              // wait for all
  scope.throwIfFailed();     // propagate any failure

  return new Dashboard(user.get(), orders.get());
}
```

`ShutdownOnFailure` is the fail-fast policy: if one task fails, the rest are
cancelled. `ShutdownOnSuccess` returns the first success and cancels the
rest.

Structured concurrency + virtual threads is the modern replacement for the
`CompletableFuture.allOf` dance.

---

## Synchronization

`synchronized` on a method or block uses the object's intrinsic lock:

```java
public synchronized void increment() {
  count++;
}

// Equivalent to
public void increment() {
  synchronized (this) {
    count++;
  }
}
```

Prefer `synchronized` on a private lock object when the lock should not be
accessible to callers:

```java
private final Object lock = new Object();
public void increment() {
  synchronized (lock) {
    count++;
  }
}
```

For read-mostly access, `ReentrantReadWriteLock` allows concurrent readers
and exclusive writers. For more complex coordination, `ReentrantLock` has
features `synchronized` lacks (try-lock, fairness, interruptible).

```java
private final ReentrantLock lock = new ReentrantLock();
public void update(Data d) {
  lock.lock();
  try { state.update(d); } finally { lock.unlock(); }
}
```

Always `unlock` in a `finally` — otherwise an exception leaks the lock.

---

## Atomics

For single-variable operations, atomic types are lock-free and faster:

```java
private final AtomicLong counter = new AtomicLong();
counter.incrementAndGet();        // atomic
counter.compareAndSet(0, 1);      // atomic CAS

private final AtomicReference<Config> config = new AtomicReference<>(initial);
config.set(updated);
```

For compound state changes, atomics aren't enough — use a lock.

`LongAdder`/`DoubleAdder` are faster than `AtomicLong` under high contention
(internally striped across cores).

---

## Thread-Safe Collections

| Use | Reach for |
|---|---|
| Concurrent map | `ConcurrentHashMap` |
| Bounded queue | `ArrayBlockingQueue` |
| Unbounded queue | `LinkedBlockingQueue` |
| Priority queue | `PriorityBlockingQueue` |
| Lock-free queue | `ConcurrentLinkedQueue` |
| Immutable snapshot | `List.copyOf(...)` / `Map.copyOf(...)` |

Don't use `Hashtable`, `Vector` — legacy synchronized wrappers. They
synchronize each operation but provide no help for compound operations.

```java
// Bad — race between containsKey and put
if (!map.containsKey(key)) {
  map.put(key, compute(key));
}

// Good — atomic
map.computeIfAbsent(key, this::compute);
```

`Collections.synchronizedMap(...)` is similar legacy; use
`ConcurrentHashMap`.

---

## Don't Share Mutable State

The simplest concurrency story is **don't share mutable state**. Pass
immutable data between threads:

```java
// Bad — mutable state shared
class Cache {
  private final Map<String, User> data = new HashMap<>();   // unsafe
}

// Good — confine to one thread, or use a thread-safe map
class Cache {
  private final Map<String, User> data = new ConcurrentHashMap<>();
}

// Best — return immutable snapshots
class UserService {
  public List<User> activeUsers() {
    return List.copyOf(loadActive());      // caller can't mutate
  }
}
```

Records are immutable by default. Use them for messages between threads.

---

## Cancellation: Honor Interruption

Long-running code should check `Thread.currentThread().isInterrupted()`
and exit cleanly:

```java
while (!Thread.currentThread().isInterrupted()) {
  try {
    var batch = queue.poll(1, TimeUnit.SECONDS);
    if (batch != null) process(batch);
  } catch (InterruptedException e) {
    Thread.currentThread().interrupt();   // restore the flag
    return;
  }
}
```

`InterruptedException` clears the interrupt flag — restore it with
`Thread.currentThread().interrupt()` if you don't fully handle the
interruption (which is most of the time).

---

## Common Pitfalls

| Pitfall | Cause | Fix |
|---|---|---|
| Race on check-then-act | Compound op without atomicity | `computeIfAbsent`, atomic, or lock |
| Deadlock | Two threads acquire locks in different orders | Always acquire in the same order |
| Livelock | Two threads keep yielding to each other | Step back; add jitter |
| Thread starvation | One task holds a shared resource too long | Bounded operations, fairness |
| `volatile` misused | Used for compound state | `volatile` is only for single-field publication |

---

## `volatile`

`volatile` guarantees **visibility** but not **atomicity**. Use for:

- Single-write publication of an immutable reference.
- A flag set by one thread, read by another.

```java
private volatile boolean shutdown = false;

public void requestShutdown() { shutdown = true; }
public void run() {
  while (!shutdown) { ... }
}
```

Don't use `volatile` for counters — `volatile int count; count++;` is still
a race.

---

## ThreadLocal

`ThreadLocal` gives each thread its own value. Useful for:

- Request-scoped context (user, trace ID) in thread-per-request servers.
- Non-thread-safe utilities used per-thread (`DateFormat`).

```java
private static final ThreadLocal<DateFormat> FMT =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
```

Watch out: in pooled threads, ThreadLocal values persist across requests
unless you remove them. Use `try { ... } finally { tl.remove(); }`.

In Java 21+, `ScopedValue` (incubator) is the modern alternative —
explicit bind/unbind, immutable, integrates with structured concurrency.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Pool for I/O | `Executors.newVirtualThreadPerTaskExecutor` |
| Pool for CPU | `Executors.newFixedThreadPool(cores)` |
| Compose async | `CompletableFuture` or `StructuredTaskScope` |
| Concurrent map | `ConcurrentHashMap` |
| Counter | `AtomicLong` / `LongAdder` |
| Flag | `volatile boolean` |
| Mutex | `synchronized` or `ReentrantLock` |
| Read-mostly | `ReentrantReadWriteLock` |
| Per-thread state | `ThreadLocal` (or `ScopedValue` in 21+) |
| Cancel | Check `Thread.isInterrupted()` |

## Related Skills

- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for `InterruptedException`.
- **Methods/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for `Runnable`/`Callable`.
- **Data structures**: [java-data-structures](../java-data-structures/SKILL.md) for thread-safe collections.
- **Performance**: [java-performance](../java-performance/SKILL.md) for virtual threads vs pools.
- **Logging**: [java-logging](../java-logging/SKILL.md) for MDC across thread boundaries.
- **Testing**: [java-testing](../java-testing/SKILL.md) for concurrency testing strategies.
