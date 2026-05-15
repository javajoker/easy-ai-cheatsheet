/*
 * Canonical Javadoc shapes for module/package, class, method, and record.
 * Copy as the starting scaffold for documenting a new module.
 */

package com.acme.myapp.example;

/**
 * Charges customers via the configured payment provider.
 *
 * <p>This class is thread-safe; the underlying HTTP client is assumed to
 * be thread-safe (Apache HttpClient and OkHttp are). Intended for use as
 * a Spring singleton bean.
 *
 * @since 1.0
 */
public final class ChargeService {

    private final Object client;

    /**
     * Constructs a charge service backed by the given client.
     *
     * @param client The HTTP client used for all outbound calls; must not be null.
     */
    public ChargeService(Object client) {
        this.client = java.util.Objects.requireNonNull(client, "client");
    }

    /**
     * Charges the customer for the given amount.
     *
     * <p>Use {@link #refund(String)} to reverse a successful charge.
     *
     * @param customerId Stripe customer ID; must start with {@code cus_}.
     * @param amountCents Amount in cents; must be {@code >= 50} (Stripe minimum).
     * @return The Stripe charge ID on success.
     * @throws IllegalArgumentException If {@code amountCents < 50}.
     * @since 1.0
     */
    public String charge(String customerId, int amountCents) {
        if (amountCents < 50) {
            throw new IllegalArgumentException("amountCents must be >= 50");
        }
        return "ch_placeholder";
    }

    /**
     * Refunds a previously successful charge.
     *
     * @param chargeId Stripe charge ID returned by {@link #charge}.
     */
    public void refund(String chargeId) {
        // ...
    }

    /**
     * @deprecated Use {@link #charge(String, int)} instead. Will be removed in 2.0.
     */
    @Deprecated(since = "1.4.0", forRemoval = true)
    public String chargeLegacy(String customerId, int cents) {
        return charge(customerId, cents);
    }
}

/**
 * A user account known to the application.
 *
 * <p>Equality is by {@code id}; two {@link User} instances with the same id
 * are the same user regardless of other fields.
 *
 * @param id Stable, opaque identifier issued by the auth system.
 * @param email Verified primary email; lowercased.
 * @param isAdmin Whether the user has the admin role.
 */
record User(String id, String email, boolean isAdmin) {
}
