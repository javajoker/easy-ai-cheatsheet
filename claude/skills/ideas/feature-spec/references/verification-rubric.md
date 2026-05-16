# Verification rubric for a feature spec

A feature spec's section 8 ("Verification plan") is the most commonly
under-written part of the spec. This rubric is what `requirement-audit`
checks against when a spec's status flips from `draft` to `approved`.

## PASS criteria

A verification plan PASSES when **every row below is satisfied** for
each behaviour the feature introduces.

### Automated coverage

| # | Criterion | How to verify |
|---|---|---|
| A1 | Every new endpoint has at least one integration test | The plan names the test file + scenario, and the test is achievable with the project's existing test infrastructure. |
| A2 | Every new business rule has at least one unit test | The plan names the rule (e.g. "discount stacks on subtotal, not total") and the test it gates. |
| A3 | Any UI flow change has at least one E2E happy-path test | The plan names the flow + the test runner / spec file. |
| A4 | Every new error path has a test that triggers it | The plan covers 400 / 401 / 403 / 404 / 409 / 5xx paths the endpoint can return. |
| A5 | Any new background job has a test covering success + retry | Including the case where retries are exhausted. |

### Manual coverage

| # | Criterion | How to verify |
|---|---|---|
| M1 | Anything not automated has an explicit manual check | Visual layout, third-party handshake, screen-reader behaviour, dark mode, etc. Each gets an owner + timing. |
| M2 | The manual checks have a single owner per check | "QA" or "the team" is not an owner; a named person or role is. |

### Observability coverage

| # | Criterion | How to verify |
|---|---|---|
| O1 | Every user-visible failure mode has at least one metric or alert | If the feature can fail silently (e.g. background job hits a dead-letter queue), there must be an alert. |
| O2 | Every new business outcome has at least one event or counter | E.g. for "checkout discount applied", there must be a counter incrementing when it fires. |
| O3 | New metrics declare label set + type + cardinality budget | High-cardinality labels (user ID, raw URL) are flagged for review. |
| O4 | New log lines declare event name + severity + structured fields | Free-form `log.info("did the thing")` does not pass. |

## PARTIAL criteria

A plan is PARTIAL (not PASS) when:

- Some behaviours have automated coverage but others don't, and no
  explicit reason is given for the gap.
- Manual checks are listed but owners are not.
- Metrics are named but the alert thresholds are TODO with no owner.

A PARTIAL plan can still ship if the author records a follow-up in the
spec's section 11 ("Open questions") with an owner and a date — but it
cannot be marked `approved`.

## FAIL criteria

A plan FAILS when:

- The Verification section is missing entirely or is one sentence.
- Behaviours are listed but no tests are named.
- The feature can fail user-visibly with no observability path.
- Observability changes that affect billing (e.g. new high-cardinality
  metrics) lack a cardinality budget.

A FAIL plan blocks `approved` status — implementation can still happen
in `draft` if the project culture allows code-first prototyping, but
shipping requires PASS.

## Worked example

For a feature "add export-to-CSV to the report page":

**Behaviours introduced:**

1. New endpoint `POST /reports/:id/export` returns a CSV file.
2. New UI button on the report page.
3. New background job that streams large reports to S3 + emails a link.

**Verification rows:**

| Behaviour | Coverage |
|---|---|
| 1 | A1: integration test `reports.export.test.ts` covers `200 + 401 + 403 + 404`. A4: same test covers each error path. |
| 2 | A3: E2E test `reports.e2e.ts` covers click-to-download happy path. M1: manual check — verify CSV opens in Excel + Numbers + Google Sheets (owner: PM, post-deploy). |
| 3 | A5: unit test for the job (`exportReportJob.test.ts`) covers success + retry-exhausted. O1: alert on DLQ depth > 0 for this job (owner: devops-engineer, gated on devops-observability). O2: counter `reports.export.completed` + `reports.export.failed`. |

PASS — every row has automated or manual coverage, observability covers
the silent-failure path (DLQ), and counters track the outcome.
