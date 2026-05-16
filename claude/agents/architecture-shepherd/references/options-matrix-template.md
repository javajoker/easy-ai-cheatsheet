# Options Matrix Template (agent-level pointer)

The canonical template lives in `arch-assessment`:
[`skills/architecture/arch-assessment/references/assessment-template.md`](../../../skills/architecture/arch-assessment/references/assessment-template.md).

A related template at the scenario-strategist level is
[`skills/scenario/scenario-analysis/references/options-analysis-template.md`](../../../skills/scenario/scenario-analysis/references/options-analysis-template.md).

## Quick shape

```markdown
### Option <X> — <name>

| Field | Value |
|---|---|
| Description | <one paragraph> |
| Addresses pain points | <P-list> |
| Time-to-migrate | <weeks> |
| Reversibility | high / med / low |
| Team capability fit | high / med / low |
| Operational cost change | <% delta> |
| Risk profile | <one paragraph> |
| Critical assumption | <the one belief that, if wrong, makes this option fail> |
```

**Non-negotiables:**

- ≥3 options (one of which is Option 0 — do nothing).
- Each option names its critical assumption.
- Each option maps explicitly to pain points it addresses (or
  explicitly states "doesn't address P1 / P3").

## When the shepherd uses this

Phase 1 (Assessment) of [architecture-shepherd's AGENT.md](../AGENT.md).
The shepherd produces the options matrix during the assessment;
human decision authority picks; Phase 3 (Migration plan) builds
out from the chosen option.
