/*
 * Canonical JUnit 5 parameterized + AssertJ + Mockito test template.
 *
 * Copy as the starting scaffold for a new test class. Replace package,
 * imports, and subject under test.
 */

package com.acme.myapp.example;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import java.time.Duration;
import java.util.stream.Stream;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(MockitoExtension.class)
class ChargeServiceTest {

    @Mock PaymentClient client;
    ChargeService service;

    @BeforeEach
    void setUp() {
        service = new ChargeService(client);
    }

    // -----------------------------------------------------------------------
    // Parameterized: many cases share the same code path.

    @ParameterizedTest
    @CsvSource({
        "1500, ch_a",
        "5000, ch_b",
        "10000, ch_c",
    })
    void chargesTheCustomer(int amountCents, String expectedId) {
        when(client.charge("cus_123", amountCents)).thenReturn(expectedId);
        assertThat(service.charge("cus_123", amountCents)).isEqualTo(expectedId);
    }

    // -----------------------------------------------------------------------
    // ValueSource for single-arg cases.

    @ParameterizedTest
    @ValueSource(ints = {-1, 0, 49})
    void rejectsAmountBelowMinimum(int amountCents) {
        assertThatThrownBy(() -> service.charge("cus_123", amountCents))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining(">= 50");
    }

    // -----------------------------------------------------------------------
    // MethodSource for richer cases.

    @ParameterizedTest
    @MethodSource("retryScenarios")
    void retriesOnTransientFailure(String description, int attempts, boolean expectSuccess) {
        // ...
    }

    static Stream<Arguments> retryScenarios() {
        return Stream.of(
            Arguments.of("first attempt fails, second succeeds", 2, true),
            Arguments.of("all three attempts fail",              3, false)
        );
    }

    // -----------------------------------------------------------------------
    // Nested @DisplayName for grouped scenarios.

    @Nested
    @DisplayName("when the network times out")
    class WhenNetworkTimesOut {

        @Test
        void retriesUpToTheConfiguredLimit() {
            // ...
        }

        @Test
        void surfacesTimeoutExceptionAfterMaxRetries() {
            // ...
        }
    }

    // Stubs to keep the template compile-clean.
    interface PaymentClient {
        String charge(String customerId, int amountCents);
    }

    static class ChargeService {
        private final PaymentClient client;
        ChargeService(PaymentClient client) { this.client = client; }
        public String charge(String customerId, int amountCents) {
            if (amountCents < 50) throw new IllegalArgumentException("amountCents must be >= 50");
            return client.charge(customerId, amountCents);
        }
    }
}
