---
name: java-performance
description: Use when profiling or optimizing Java performance — JVM tuning, GC, allocation pressure, hot loops, JIT behavior, virtual threads vs platform threads, string operations, collections in hot paths, JSON parsing. Also use when investigating high latency, OOM, or GC pauses.
license: Apache-2.0
metadata:
  sources: "Java Performance: The Definitive Guide, JEP 444 (virtual threads), G1/ZGC/Shenandoah docs"
---

# Java Performance

## Measure First

Don't optimize before measuring.

| Tool | When |
|---|---|
| **JFR (Java Flight Recorder)** | Production-safe profiling, included in OpenJDK |
| **`jcmd`** | Trigger JFR, heap dumps, thread dumps |
| **async-profiler** | Low-overhead CPU + memory profiling; flamegraphs |
| **JMH** | Microbenchmarks |
| **VisualVM / JConsole** | Live monitoring |
| **Eclipse MAT** | Heap dump analysis (memory leaks) |

```bash
# Start a 60-second JFR recording
jcmd <pid> JFR.start duration=60s filename=profile.jfr

# Take a heap dump
jcmd <pid> GC.heap_dump /tmp/heap.hprof

# Thread dump
jcmd <pid> Thread.print
```

JFR has near-zero overhead and runs in production. Use it before reaching
for async-profiler.

---

## Virtual Threads (Java 21+)

Virtual threads make thread-per-request cheap. Use them for blocking I/O:

```java
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
  for (var task : tasks) {
    exec.submit(task);
  }
}
```

A web server with virtual threads enabled handles tens of thousands of
concurrent connections without thread-pool tuning.

**Virtual threads are not faster for CPU-bound work.** They're faster for
blocking work because they don't tie up an OS thread.

For CPU-bound work, a fixed pool sized to the CPU count is still right.

```java
var cpuExec = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
```

---

## GC Choice

| GC | Best for |
|---|---|
| **G1** | Default since Java 9. Balanced; works for most workloads. |
| **ZGC** | Low-pause (< 1 ms) for large heaps (multi-GB). Java 15+ |
| **Shenandoah** | Similar low-pause goal as ZGC; Red Hat origin. |
| **Parallel** | Throughput-optimized (batch jobs, no latency SLA). |
| **Serial** | Tiny heaps; not for servers. |

For services with latency SLAs and heaps > 4 GB, **ZGC** is usually the
right answer in Java 21+. For most application heaps under 4 GB, **G1**
with default tuning is fine.

```bash
# Enable ZGC
java -XX:+UseZGC -Xmx8g -jar app.jar
```

Set `-Xms` and `-Xmx` to the same value in production to avoid heap
resizing pauses.

---

## Allocation Pressure

Every `new` allocates. Hot-loop allocations pile up and trigger GC.

Patterns that help:

- **`StringBuilder`** instead of `String` concatenation in loops:
  ```java
  // Bad — O(n²)
  String result = "";
  for (String s : parts) result += s;

  // Good — O(n)
  StringBuilder sb = new StringBuilder();
  for (String s : parts) sb.append(s);
  return sb.toString();
  ```
- **Primitive streams** in numeric work — `IntStream`, `LongStream` —
  avoid boxing.
- **`final` fields** and **records** let JIT inline accessors.
- **Reuse buffers** in hot I/O paths instead of allocating per call.

Cold-path code: don't bother. Readability wins.

---

## String Operations

`String.format` is slower than `+` or `StringBuilder`. Use it for
readability when it's not on a hot path; use `StringBuilder` (or
`String.join`, `Arrays.toString`) when it is.

Java 15+ `formatted` is no faster than `String.format` — it's an
ergonomic improvement, not a perf one.

`String.repeat`, `String.indent`, `String.lines`, and text blocks are
fast — use them.

For high-throughput logging, SLF4J placeholders (`{}`) avoid concatenation
when the level is filtered out. See [java-logging](../java-logging/SKILL.md).

---

## Collections in Hot Paths

| Want | Reach for |
|---|---|
| Index access | `ArrayList` (contiguous memory) over `LinkedList` |
| Iteration | `ArrayList` over `LinkedList` |
| Membership | `HashSet` (O(1)) over `ArrayList.contains` (O(n)) |
| Enum keys | `EnumMap`, `EnumSet` (bit-field backed) |
| Concurrent map | `ConcurrentHashMap` |

`LinkedList` looks like a list but its random access is O(n). It's almost
never the right answer.

For micro-optimization in numeric work, primitive collections (Eclipse
Collections, Fastutil) avoid boxing and can be much faster than
`Map<Integer, Integer>`. Reach for them only when JFR identifies a
boxing hot spot.

---

## JSON Performance

Jackson is the default. Tuning:

- Configure `ObjectMapper` once; reuse it (it's thread-safe).
- Use `@JsonInclude(NON_NULL)` to skip nulls in output (smaller payloads).
- Pre-compile `JavaType` references for repeated polymorphic
  deserialization.

For very high throughput, **DSL-JSON** is ~2-5× faster than Jackson at the
cost of compile-time codegen.

For streaming JSON in/out without materializing the whole graph, use
Jackson's `JsonParser` / `JsonGenerator` directly.

---

## Connection Pooling

For DB connections, use **HikariCP** (Spring Boot's default):

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 5000
      validation-timeout: 5000
```

Pool size: start with `2 * CPUs + spindles`. Larger isn't better — too
many connections compete for the DB's threads.

For outbound HTTP, share an HTTP client. Spring's `RestClient` / `WebClient`
should be singleton beans, not created per request.

---

## Caching

The cheapest call is the one you don't make.

- **Caffeine** — in-process LRU/LFU cache. Default for new code.
- **Spring `@Cacheable`** — declarative, backed by Caffeine or Redis.
- **Redis** — shared cache across instances.

```java
Cache<String, User> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(Duration.ofMinutes(5))
    .build();

User user = cache.get(id, k -> repo.findById(k).orElseThrow());
```

Watch for cache stampedes: many concurrent misses hit the upstream. Use
`CompletableFuture`-based or single-flight patterns.

---

## JIT Warmup

The JIT compiles hot methods at runtime, getting faster over the first
seconds-to-minutes of execution. Consequences:

- **Microbenchmarks** must warm up. JMH handles this — don't roll your own.
- **First requests** are slower than steady-state. Tune health-check
  windows to allow warmup before peak traffic.
- **GraalVM native image** trades startup speed for some peak throughput.
  Worth it for serverless / edge; trade-off for steady-state services.

---

## JFR for Production

Always-on JFR is essentially free. Enable a continuous recording with a
rotating buffer:

```bash
java -XX:StartFlightRecording=delay=10s,duration=24h,filename=app.jfr,maxsize=1g \
     -jar app.jar
```

When latency or memory anomalies happen, the JFR file already has the
profile data — no need to reproduce the issue. The Java Mission Control
GUI reads JFR.

---

## Common Pitfalls

| Symptom | Look at |
|---|---|
| High latency, low CPU | I/O — DB, upstream, sync FS |
| High CPU | Hot loops; profile to find them |
| GC sawtooth | Allocation pattern; reduce or pool |
| OOM | Heap dump + Eclipse MAT to find retained sets |
| Threads exhausted | Missing timeouts; move to virtual threads |
| Slow first request | JIT warmup; tune health-check window |
| Slow startup | Class loading; consider AOT or class-data sharing (CDS) |

---

## Don't Pre-Optimize

Most Java performance work in modern apps comes down to:

1. Move blocking I/O to virtual threads.
2. Set explicit timeouts everywhere.
3. Cache the expensive lookup.
4. Use primitive types in genuine hot loops.
5. Eliminate `LinkedList` and `Hashtable`.

That's 95 % of the gain. Custom `Unsafe` tricks, `sun.misc.*` access,
hand-rolled lock-free data structures — these are for the remaining 5 %
and require profile evidence.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Profiling in production | JFR + Java Mission Control |
| CPU profile flamegraph | async-profiler |
| Microbenchmark | JMH |
| Blocking I/O concurrency | Virtual threads |
| CPU-bound concurrency | Fixed pool sized to cores |
| Default GC | G1 (or ZGC for large heaps) |
| Hot string concat | `StringBuilder` |
| Hot numeric | Primitive types / `IntStream` |
| DB pool | HikariCP, ~`2*CPUs` size |
| In-process cache | Caffeine |

## Related Skills

- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for virtual threads.
- **Data structures**: [java-data-structures](../java-data-structures/SKILL.md) for hot-path container choice.
- **HTTP**: [java-http](../java-http/SKILL.md) for client reuse and timeouts.
- **Logging**: [java-logging](../java-logging/SKILL.md) for async appenders and placeholder logging.
- **Style core**: [java-style-core](../java-style-core/SKILL.md) for `StringBuilder` defaults.
