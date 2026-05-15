/**
 * Public summary of what this module does, in one sentence.
 *
 * <p>Additional paragraphs explain context, design rationale, or unusual
 * constraints — anything that the symbol's name and type don't say.
 *
 * @packageDocumentation
 */

/**
 * One-sentence summary of what the function does.
 *
 * Additional paragraphs explain why the function exists, when to prefer it
 * over alternatives, and any constraints the type can't carry (units,
 * ranges, side effects, ordering guarantees).
 *
 * @param customerId - Stripe customer ID; must start with `cus_`.
 * @param amountCents - Amount in cents; must be ≥ 50 (Stripe minimum).
 * @returns Stripe charge ID on success.
 * @throws {@link InsufficientFundsError} When the card was declined.
 *
 * @example
 * ```ts
 * const id = await charge('cus_123', 1500);
 * ```
 */
export async function charge(customerId: string, amountCents: number): Promise<string> {
  // implementation
  return '';
}

/**
 * A user account known to the application.
 *
 * @remarks
 * Equality is by `id`. Two `User` instances with the same id are
 * considered the same user regardless of other fields.
 */
export interface User {
  /** Stable, opaque identifier issued by the auth system. */
  readonly id: string;
  /** Verified primary email; lowercased. */
  readonly email: string;
  /** True iff the user has the admin role. */
  readonly isAdmin: boolean;
}

/**
 * Configuration for retry-with-backoff.
 *
 * @defaultValue
 * `{ maxAttempts: 3, baseDelayMs: 100 }` — call sites that omit fields use these defaults.
 */
export interface RetryOptions {
  /** Maximum total attempts including the first call; must be ≥ 1. */
  maxAttempts?: number;
  /** Initial backoff in milliseconds; doubles each retry. */
  baseDelayMs?: number;
}

/**
 * @deprecated Use {@link charge} instead. Will be removed in v3.
 */
export async function chargeLegacy(customerId: string, cents: number): Promise<string> {
  return charge(customerId, cents);
}
