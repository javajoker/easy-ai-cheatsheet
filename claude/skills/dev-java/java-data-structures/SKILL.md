---
name: java-data-structures
description: Use when choosing or working with Java collections — `List`, `Map`, `Set`, `Deque`, `Queue`, immutable factory methods (`List.of`), `Stream` API, `Collectors`, and `Iterator`. Also use when designing data flow, applying defensive copies at API boundaries, or replacing imperative loops with stream pipelines.
license: Apache-2.0
metadata:
  sources: "Java Collections Framework docs, Effective Java (Items 47-50), Stream API tutorial"
---

# Java Collections and Streams

## Pick the Right Collection

| Need | Reach for |
|---|---|
| Ordered, indexable | `ArrayList<T>` |
| Linked list semantics (rare) | `LinkedList<T>` |
| Key → value | `HashMap<K, V>` |
| Insertion-ordered map | `LinkedHashMap<K, V>` |
| Sorted map | `TreeMap<K, V>` (Comparator) |
| Unique items | `HashSet<T>` |
| Insertion-ordered set | `LinkedHashSet<T>` |
| Sorted set | `TreeSet<T>` |
| Both-end queue | `ArrayDeque<T>` (stack/queue) |
| Concurrent map | `ConcurrentHashMap<K, V>` |
| Bounded blocking queue | `ArrayBlockingQueue<T>` |
| Enum keys | `EnumMap`, `EnumSet` (O(1), tiny) |

Defaults: `ArrayList`, `HashMap`, `HashSet`, `ArrayDeque`. Reach for the
others when you have a reason (ordering, sorting, concurrency).

---

## Immutable Factory Methods (Java 9+)

```java
List<String> names = List.of("Alice", "Bob", "Charlie");
Set<Integer> primes = Set.of(2, 3, 5, 7);
Map<String, Integer> ages = Map.of("Alice", 30, "Bob", 28);

// More than 10 entries
Map<String, Integer> many = Map.ofEntries(
    Map.entry("Alice", 30),
    Map.entry("Bob", 28),
    Map.entry("Charlie", 35)
);
```

These return immutable collections — modification throws
`UnsupportedOperationException`. Use them for constants and small fixed
data.

For an immutable snapshot of an existing collection:

```java
List<User> snapshot = List.copyOf(mutableList);
Map<String, User> mapSnapshot = Map.copyOf(mutableMap);
```

---

## Return Interface Types

```java
// Bad — locks the implementation
public ArrayList<User> activeUsers() { ... }

// Good — interface
public List<User> activeUsers() { ... }
```

The caller couples to the interface, not your choice of implementation.
Switching `ArrayList` to `LinkedList` is a free refactor.

---

## Never Return `null` Collections

```java
// Bad
public List<User> activeUsers() {
  if (db.isDown()) return null;     // surprise NPE
  return ...;
}

// Good
public List<User> activeUsers() {
  if (db.isDown()) return List.of();
  return ...;
}
```

Empty collection is the right "no items" signal. Callers can iterate, count,
and pipe through streams without null-checking.

---

## Defensive Copy at the Boundary

When you accept a collection and store it, or return one you own, copy at
the boundary to prevent shared mutation:

```java
public class UserGroup {
  private final List<User> users;   // owned

  public UserGroup(List<User> users) {
    this.users = List.copyOf(users);   // defensive copy in
  }

  public List<User> users() {
    return users;                       // already immutable, safe to return
  }
}
```

`List.copyOf` is cheap when the input is already an immutable list (it
returns the same instance). For mutable input it allocates.

---

## Map Operations

```java
// Get with default
String name = map.getOrDefault(id, "unknown");

// Atomic put-if-absent
map.putIfAbsent(id, user);

// Compute if missing
Group g = groups.computeIfAbsent(key, k -> new Group(k));

// Merge values
counts.merge(key, 1, Integer::sum);   // count++ pattern

// Iterate entries
for (var entry : map.entrySet()) {
  process(entry.getKey(), entry.getValue());
}
```

`computeIfAbsent` and `merge` are the right tools for "build a map of
groups" or "increment a counter" patterns. They're also atomic on
`ConcurrentHashMap`.

---

## Stream API

Use streams when the operation reads as a pipeline (filter, map, reduce):

```java
List<String> emails = users.stream()
    .filter(User::isActive)
    .map(User::email)
    .filter(e -> !e.isBlank())
    .toList();
```

Don't use streams when:

- The body needs side effects (use a `for-each` loop).
- It's a single pass with no transformation (use a loop).
- It would have one statement per stage (use a loop — overkill).

```java
// Bad — stream for a side effect
users.stream().forEach(this::send);

// Good — for-each
for (var user : users) {
  send(user);
}
```

`forEach` on a stream is the smell — if you're stream-producing for the
side effect, the stream is the wrong tool.

---

## Common Collectors

```java
import static java.util.stream.Collectors.*;

// To list / set / map
List<String> emails = stream.toList();              // Java 16+; immutable
Set<String> uniqueEmails = stream.collect(toSet());
Map<String, User> byId = users.stream().collect(toMap(User::id, u -> u));

// Group by
Map<Country, List<User>> byCountry =
    users.stream().collect(groupingBy(User::country));

// Group by + count
Map<Country, Long> countByCountry =
    users.stream().collect(groupingBy(User::country, counting()));

// Partition (binary group)
Map<Boolean, List<User>> activeAndOther =
    users.stream().collect(partitioningBy(User::isActive));

// Join strings
String csv = names.stream().collect(joining(", ", "[", "]"));
```

Java 16+ added `Stream.toList()` — immutable, replaces
`.collect(toUnmodifiableList())` for common cases.

---

## Don't Modify the Source in a Stream

```java
// Bad — modifying source mid-stream
List<User> users = new ArrayList<>(...);
users.stream()
    .filter(u -> {
      if (!u.isActive()) users.remove(u);   // ConcurrentModificationException
      return true;
    })
    .toList();

// Good — produce new
List<User> active = users.stream()
    .filter(User::isActive)
    .toList();
```

Streams describe a pipeline; they don't mutate the source. Mutating
violates the contract and breaks.

---

## Primitive Streams

For numeric work, `IntStream`, `LongStream`, `DoubleStream` avoid boxing:

```java
int sum = users.stream()
    .mapToInt(User::age)
    .sum();

IntStream.range(0, 100)
    .filter(i -> i % 2 == 0)
    .forEach(System.out::println);
```

Convert with `boxed()` if you need a `Stream<Integer>`.

---

## Parallel Streams

`.parallel()` runs on the common ForkJoinPool. Use it only when:

- The dataset is large enough (typically thousands of elements).
- Each operation is genuinely parallelizable (no shared mutable state).
- Order doesn't matter (or you handle it explicitly).
- Profile shows it helps.

For most application code, parallel streams are not a free speedup — the
ForkJoinPool is shared, and the overhead of splitting can exceed the gain.

```java
long count = users.parallelStream()
    .filter(this::isExpensiveCheck)
    .count();
```

---

## Iterator and `Iterable`

For custom collections, implement `Iterable<T>` so `for-each` works:

```java
public class PagedResults<T> implements Iterable<T> {
  @Override
  public Iterator<T> iterator() {
    return new Iterator<>() {
      private Iterator<T> currentPage = loadPage(0).iterator();
      private int pageNum = 0;

      @Override
      public boolean hasNext() {
        if (currentPage.hasNext()) return true;
        currentPage = loadPage(++pageNum).iterator();
        return currentPage.hasNext();
      }

      @Override
      public T next() {
        if (!hasNext()) throw new NoSuchElementException();
        return currentPage.next();
      }
    };
  }
}
```

---

## `Collections` Utility Methods

```java
Collections.sort(list);                          // mutates the list
Collections.reverse(list);                       // mutates
Collections.shuffle(list);                       // mutates
Collections.emptyList();                          // legacy; use List.of()
Collections.unmodifiableList(list);              // view; mutations to underlying still show
Collections.synchronizedList(list);              // legacy; use ConcurrentXxx
```

For immutable copy, prefer `List.copyOf(list)` (creates real copy) over
`Collections.unmodifiableList(list)` (creates a view).

---

## Quick Reference

| Need | Reach for |
|---|---|
| Default list / map / set | `ArrayList` / `HashMap` / `HashSet` |
| Small constant | `List.of(...)`, `Map.of(...)`, `Set.of(...)` |
| Snapshot | `List.copyOf`, `Map.copyOf` |
| Transform | `stream().map().toList()` |
| Filter + transform | `stream().filter().map().toList()` |
| Group by | `Collectors.groupingBy` |
| Counter | `merge(key, 1, Integer::sum)` |
| Lazy load missing | `computeIfAbsent` |
| Iterate items | `for-each` |
| Return collection | Interface (`List<T>`), never null, defensive copy |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for `var` on locals.
- **Types**: [java-types](../java-types/SKILL.md) for records as collection elements.
- **Generics**: [java-generics](../java-generics/SKILL.md) for `Collection<? extends E>`.
- **Methods/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for stream-friendly lambdas.
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for `ConcurrentHashMap`.
- **Performance**: [java-performance](../java-performance/SKILL.md) for primitive streams and boxing.
