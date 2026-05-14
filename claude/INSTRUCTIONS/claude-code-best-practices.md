# Claude Code Best Practices

> Generic Claude Code workflow guidance, language- and project-agnostic.

## Core idea

Claude Code is an **agentic coding environment**. Unlike a chat interface,
Claude can:

- Read files and run commands.
- Modify code and verify its own work in a loop.
- Delegate to subagents for parallel work.

This changes the working model: **you describe what you want; Claude decides
how to build it.** That works only if Claude can verify when it is done.

## The single most important constraint

**The context window fills quickly, and quality degrades with it.**

Context includes:

- The full conversation history.
- Every file Claude reads.
- The output of every command.

**Context management is the most important resource decision in every session.**

## Top practices

### 1. Give Claude a way to verify its work

The single highest-leverage habit. Include tests, expected outputs, or both,
so Claude can self-check.

```
Bad:
"Implement Redis multi-instance management"

Good:
"Implement redis.Manager.GetClient(name string).
 Tests:
   existing name → returns the configured client, no error
   unknown name  → returns ErrClientNotFound
 After implementing, run `go test ./redis/...`"
```

The bad example forces Claude to guess at acceptance criteria. The good
example makes done explicit and machine-checkable.

### 2. Explore → Plan → Implement

Three distinct phases. Run them in order; do not collapse them.

**Phase 1 — Explore (Plan Mode is helpful here)**
- Read the relevant files.
- Understand the existing patterns and conventions.

**Phase 2 — Plan (Plan Mode is mandatory here for non-trivial work)**
- List the files to touch.
- State the new structures, signatures, or migrations.
- Identify the verification steps.

**Phase 3 — Implement (Normal Mode)**
- Apply the plan one step at a time.
- Verify each step against the criteria from Phase 2.

When to skip the plan:
- The change is one or two lines with a clear right answer.
- You can describe the entire diff in one sentence.

Otherwise plan first — the cost of planning is much less than the cost of
unwinding a wrong implementation.

### 3. Specific context in prompts

Claude can infer intent but cannot read minds. Cite files, point at examples.

| Strategy | Bad | Good |
|---|---|---|
| Specify scope | "add tests" | "add tests for `getCurrentUser` in `auth/handler.go`" |
| Cite a pattern | "create a new package" | "create a new package modelled after `databases/` — same Init/Get pattern" |
| Describe symptoms | "fix the concurrency bug" | "when N goroutines call Init concurrently, `manager` is sometimes nil — investigate the sync.Once usage" |

### 4. Provide rich content

- Reference files inline with `@filename`.
- Paste error output directly — full stack traces, not summaries.
- Provide library documentation URLs when the work depends on third-party APIs.

## Configuring the environment

### CLAUDE.md

Run `/init` to generate a baseline `CLAUDE.md` for the project. Then iterate.

**Keep it short.** `CLAUDE.md` is loaded into every session.

| Include | Exclude |
|---|---|
| Build/test commands Claude cannot guess | Information Claude can derive from code |
| Style rules that differ from language defaults | Detailed API documentation (link to it instead) |
| Repo etiquette (branch naming, PR convention) | Frequently-changing facts |
| Project-specific architecture decisions | File-by-file codebase descriptions |

When `CLAUDE.md` exceeds ~150 lines, split per-area instructions into
`INSTRUCTIONS/` or per-skill SKILL.md files; keep `CLAUDE.md` as the index.

### Permissions

`claude --permission-mode auto -p "<task>"` reduces interrupt rate for trusted,
well-scoped tasks. Avoid `auto` for tasks that involve destructive operations,
public-facing systems, or sensitive files.

### MCP servers

`claude mcp add` connects external tools. Common adds:

- GitHub via `gh` CLI (PRs, issues, releases).
- Database query tools (for inspection during development).
- Project-specific MCPs declared in `projects/<name>/`.

## Communicating effectively

### Ask the codebase as if asking a senior engineer

- "How does the `databases` package handle read/write splitting?"
- "How do I register a route with a path parameter in `http_server`?"
- "What is the dependency between `HTTPServerComponent` and `GRPCServerComponent` in `app/components/server.go`?"

### Let Claude interview you for new features

Before a meaningful new feature, ask Claude to interview you and produce a
spec:

```
I want to add an Elasticsearch integration. Use AskUserQuestion to interview
me. Ask about: which operations to support, connection management style,
compatibility with the existing Init/Get pattern. After, write SPEC.md.
```

This produces a much higher-quality spec than free-form description.

## Managing the session

### Correct early

- `Esc` — interrupt without losing context; redirect.
- `Esc Esc` or `/rewind` — restore prior conversation and code state.
- `/clear` — reset context between unrelated tasks.

If the same correction is needed more than twice, run `/clear` and rewrite the
prompt with the gathered context — do not keep nudging.

### Actively manage context

- Use `/clear` between unrelated tasks.
- Name sessions with `/rename` so they stay searchable.
- Use subagents for read-heavy investigations to keep the main thread clean.

### Companion skills

Three skills in `skills/share/` exist precisely for context management:

- **`cognitive-alignment`** — surface and confirm shared meaning when terms
  are ambiguous.
- **`memory-ontology`** — promote durable facts so the next session starts
  better than this one ended.
- **`compact-ritual`** — protect the above when `/compact` runs.

Run them proactively. They are cheap and prevent expensive failures.

## Automation and scale

### Non-interactive mode

```bash
claude -p "Explain the topological sort in app/container.go"
claude -p "List all Init function signatures in the project" --output-format json
```

### Writer/reviewer

A clean separation of concerns: one session writes, a different session reviews
the diff with fresh context.

| Session A (Writer) | Session B (Reviewer) |
|---|---|
| Implement the new feature in `redis` package | — |
| — | Review `@redis/redis.go` for concurrency issues and missing error handling |
| Address reviewer feedback | — |

## Failure modes to avoid

| Pattern | What goes wrong | Fix |
|---|---|---|
| **Kitchen-sink session** | Unrelated tasks in one session, context muddled | `/clear` between unrelated tasks |
| **Repeated correction** | Claude gets it wrong; you nudge; still wrong; repeat | After two nudges, `/clear` and rewrite the prompt |
| **Over-stuffed `CLAUDE.md`** | Too long, Claude starts ignoring rules | Trim ruthlessly or move to hooks |
| **Trust without verify** | Reasonable-looking implementation that is subtly wrong | Always require verifiable acceptance criteria |
| **Unscoped exploration** | "Investigation" reads hundreds of files | Narrow the scope or use a subagent |

## A reference workflow

For a non-trivial change in any project:

```
Phase 1 — Explore (Plan Mode)
> Read the relevant existing packages and conventions
> Identify the pattern this new work should follow

Phase 2 — Plan (Plan Mode)
> Describe the new package or change
> List files touched, signatures introduced, tests to write

Phase 3 — Implement (Normal Mode)
> Implement against the plan, one step at a time
> Add tests as you go
> Verify each step

Phase 4 — Verify
> Run language-appropriate build, static-check, and test commands
> See projects/<name>/ for the exact commands
```

## Resources

- [Claude Code documentation](https://code.claude.com/docs)

---

**Version**: 3.0.0
**Updated**: 2026-05-13
