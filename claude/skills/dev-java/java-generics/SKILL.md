---
name: java-generics
description: Use when writing or reviewing Java generics — type parameters, wildcards, PECS (producer-extends, consumer-super), bounded type parameters, recursive bounds, generic methods, and type erasure pitfalls. Also use when refactoring raw types or designing a reusable generic API.
license: Apache-2.0
metadata:
  sources: "Effective Java (Items 26-33), Angelika Langer Generics FAQ, JEP 218 (Reified generics — historical)"
---

# Java Generics

## Why Generics

Without generics, collections hold `Object` and require casts:

```java
// Bad — raw, no type safety
List list = new ArrayList();
list.add("hello");
String s = (String) list.get(0);   // unchecked cast
list.add(42);                       // accepted; will explode at use

// Good — type-safe at compile time
List<String> list = new ArrayList<>();
list.add("hello");
String s = list.get(0);             // no cast
list.add(42);                        // compile error
```

The compiler checks types at use sites. Generic code is also self-documenting:
`Map<UserId, User>` says everything.

---

## Diamond Operator

For local declarations, let the right side infer:

```java
// Old
Map<String, List<User>> map = new HashMap<String, List<User>>();

// Good
Map<String, List<User>> map = new HashMap<>();
```

For fields and method returns, the explicit type on the left is the
documentation. The diamond on the right is just type inference.

---

## Bounded Type Parameters

When you need to call methods on the type parameter, constrain it:

```java
// Bad — T is Object; can't compare
public static <T> T max(List<T> list) { ... }

// Good — bounded
public static <T extends Comparable<T>> T max(List<T> list) {
  T result = list.get(0);
  for (T x : list) {
    if (x.compareTo(result) > 0) result = x;
  }
  return result;
}
```

The bound `<T extends Comparable<T>>` says "T must be a type that can compare
itself to T".

For multiple bounds, separate with `&`:

```java
public <T extends Number & Comparable<T>> T pickGreater(T a, T b) { ... }
```

---

## PECS: Producer Extends, Consumer Super

Wildcards make APIs flexible. Two rules:

- **Producer** (you'll **read** Ts from it): `? extends T`.
- **Consumer** (you'll **write** Ts to it): `? super T`.

```java
public static <T> void copy(List<? extends T> source, List<? super T> dest) {
  for (T item : source) dest.add(item);
}

List<Integer> ints = ...;
List<Number> numbers = ...;
copy(ints, numbers);   // ok: Integer extends Number; ints produce, numbers consume
```

Without wildcards, `copy(List<T> source, List<T> dest)` would refuse the
above call (`List<Integer>` is not `List<Number>` — generic types are
invariant by default).

```java
// Producer (we read from it)
public void addAll(Collection<? extends T> source) { ... }

// Consumer (we write to it)
public void drainInto(Collection<? super T> sink) { ... }

// Both (we both read and write) — use T, not wildcards
public void shuffle(List<T> list) { ... }
```

---

## `?` Unbounded Wildcard

`List<?>` is "list of unknown". You can read but only as `Object`; you can't
add anything except `null`.

```java
void printAll(List<?> list) {
  for (Object o : list) {
    System.out.println(o);
  }
  // list.add("x");   // compile error
}
```

Use for read-only iteration when the element type doesn't matter.

---

## Generic Methods

Type parameters declared on a method are scoped to that method:

```java
public static <T> List<T> singletonList(T item) {
  return List.of(item);
}

// Call site usually doesn't specify
List<String> single = singletonList("hi");
List<Integer> oneInt = singletonList(42);
```

Use a generic method when:

- The return depends on the parameter type.
- A static utility takes elements of a parameterized type.

Don't put a type parameter on a method if it's used only as a parameter type
that the call site already knows:

```java
// Bad — caller already knows the type
public <T> void log(T value) { System.out.println(value); }

// Good
public void log(Object value) { System.out.println(value); }
```

---

## Generic Classes

```java
public class Stack<T> {
  private final List<T> data = new ArrayList<>();

  public void push(T item) { data.add(item); }
  public T pop() { return data.remove(data.size() - 1); }
}

Stack<String> stack = new Stack<>();
stack.push("hi");
```

If you have two parameters and they relate, give descriptive names:

```java
public class Cache<KeyT, ValueT> { ... }   // clearer than <K, V> when complex
```

Single-letter is fine when conventional (`T` for "type", `K`/`V` for map
key/value, `E` for collection element). Effective Java recommends keeping
them single capitals when unambiguous.

---

## Recursive Type Bounds

`<T extends Comparable<T>>` is the classic recursive bound. Looks weird;
read as "T can compare to itself".

```java
public static <T extends Comparable<T>> T max(Collection<T> coll) { ... }
```

For inheritance hierarchies where the bound must include subtypes,
F-bounded generics get more involved:

```java
public abstract class Builder<B extends Builder<B>> {
  public B withName(String n) { ... return self(); }
  protected abstract B self();
}

public class UserBuilder extends Builder<UserBuilder> {
  @Override protected UserBuilder self() { return this; }
}
```

This is the curiously-recurring-template-pattern (CRTP) in Java. Use
sparingly — many cases don't need it.

---

## Type Erasure

At runtime, `List<String>` and `List<Integer>` are both just `List`. The
JVM erases the type parameter. Consequences:

- `instanceof List<String>` is illegal (you must write `instanceof List<?>`).
- You can't `new T[size]` — the array type isn't known at runtime.
- Two methods can't differ only by parametrized type (`void f(List<String>)`
  and `void f(List<Integer>)` clash).

Workarounds:

- For arrays: `Array.newInstance(clazz, size)` with a `Class<T>` parameter.
- For runtime type: pass a `Class<T>` token alongside (the "type token" idiom).

```java
public <T> T loadAndCast(String key, Class<T> type) {
  Object obj = store.get(key);
  return type.cast(obj);
}
```

---

## Don't Mix Raw and Parameterized

```java
// Bad
List rawList = new ArrayList<String>();   // mixes raw and parameterized
rawList.add(42);                           // compiles; corrupts the list
```

The compiler issues an "unchecked" warning. Treat unchecked warnings as
errors:

```xml
<compilerArgs>
  <arg>-Xlint:all</arg>
  <arg>-Werror</arg>
</compilerArgs>
```

---

## Common API Patterns

```java
// Builder returning self
public class Request<RequestT extends Request<RequestT>> { ... }

// Generic factory
public static <T> Optional<T> tryParse(String s, Function<String, T> parser) { ... }

// Visitor with return type
public interface Visitor<R> {
  <T> R visit(Node<T> node);
}

// Result type
public sealed interface Result<T> permits Success<T>, Failure {}
public record Success<T>(T value) implements Result<T> {}
public record Failure(Throwable cause) implements Result {}
```

---

## Quick Reference

| Need | Reach for |
|---|---|
| Type-safe collection | `List<T>`, etc. |
| Generic method | Type parameter on the method |
| Generic class | Type parameter on the class |
| Bounded | `<T extends Comparable<T>>` |
| Reading from any subtype | `? extends T` |
| Writing to any supertype | `? super T` |
| Read-only iteration | `List<?>` |
| Compile-time check | `-Xlint:all -Werror` |
| Avoid | raw types, `instanceof List<String>` |

## Related Skills

- **Types**: [java-types](../java-types/SKILL.md) for primitives, records, Optional.
- **Data structures**: [java-data-structures](../java-data-structures/SKILL.md) for `Collection<? extends E>` patterns.
- **Classes**: [java-classes](../java-classes/SKILL.md) for generic class design.
- **Functions/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for `Function<T, R>`, `Predicate<T>`.
- **Naming**: [java-naming](../java-naming/SKILL.md) for type parameter conventions.
