// Canonical Vitest table-driven test template.
//
// Pattern: one describe per subject; one it.each per scenario set; named
// fields in the case row; failure messages include the input.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import { upperCase } from './upper-case.js';

describe('upperCase', () => {
  // Cases share the same code path; vary only input/output.
  it.each<{ name: string; input: string; expected: string }>([
    { name: 'ASCII',         input: 'foo',  expected: 'FOO' },
    { name: 'empty',         input: '',     expected: '' },
    { name: 'unicode',       input: 'háy',  expected: 'HÁY' },
    { name: 'mixed case',    input: 'aBc',  expected: 'ABC' },
  ])('$name → $expected', ({ input, expected }) => {
    expect(upperCase(input)).toBe(expected);
  });

  it('throws on null', () => {
    expect(() => upperCase(null as unknown as string)).toThrowError(TypeError);
  });
});

// ---------------------------------------------------------------------------
// Async + fake timers template

describe('Session', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('expires after the configured TTL', () => {
    const session = createSession({ ttlMs: 60_000 });
    vi.advanceTimersByTime(60_001);
    expect(session.isValid()).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Async test that asserts on rejection

describe('loadUser', () => {
  it('rejects with NotFoundError for unknown ids', async () => {
    await expect(loadUser('does-not-exist')).rejects.toThrowError(/not found/);
  });
});

// Stubs for the template; real tests import the real implementations.
declare function createSession(opts: { ttlMs: number }): { isValid(): boolean };
declare function loadUser(id: string): Promise<unknown>;
