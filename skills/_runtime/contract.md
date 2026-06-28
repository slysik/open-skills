# Self-Healing Blueprint Runtime — Contract

The thin substrate every platform runtime script (`sense-state`, `verify-auth`,
`diagnose-error`, `assert`, `generate-blueprint`) conforms to. One wire format so
any agent in any harness parses every script identically and chains failures into
the repair loop.

## The envelope

Every script prints **exactly one** JSON object on **stdout**:

```json
{ "status": "ok|fail|degraded", "data": {}, "diagnosis": "", "fix": "" }
```

| Field | Meaning |
| --- | --- |
| `status` | `ok` success · `fail` recoverable failure (a `fix` is provided) · `degraded` not auto-fixable (e.g. tenant-gated feature) — do **not** retry-loop |
| `data` | Arbitrary JSON object with the script's result (sensed state, assertion detail, generated paths). `{}` when none. |
| `diagnosis` | Human-readable cause. Empty on `ok`. |
| `fix` | The exact next command the agent/human runs to remediate. Empty on `ok`. Non-empty whenever `status` is `fail`. |

## Stream discipline

- **stdout = JSON only.** Nothing else. The agent pipes stdout straight to `jq`.
- **stderr = human text.** Progress, prompts, banners go here, never stdout.

## Exit codes

| Code | Constant | Meaning |
| --- | --- | --- |
| `0` | `RC_OK` | success |
| `1` | `RC_UNKNOWN` | unknown / generic failure |
| `3` | `RC_AUTH` | authentication / token expiry → route to `verify-auth` |
| `4` | `RC_GRANT` | missing privilege / grant → `diagnose-error` emits the `GRANT` |
| `5` | `RC_DRIFT` | live state differs from expected (state drift) |

`degraded` status pairs with a non-zero exit (typically `1`) but signals the
caller to stop retrying and surface guidance instead.

## Shared emitter

Scripts source `lib/emit.sh` and call:

- `emit_ok '<data-json>'` → status `ok`, exit `0`
- `emit_fail "<diagnosis>" "<fix>" [exit]` → status `fail`, exit code (default `1`)
- `emit_degraded "<diagnosis>" "<fix>" [exit]` → status `degraded`
- `runtime_require <cmd>...` → preflight; emits a `fail` envelope with an install `fix` if a dependency is missing

`emit.sh` works with or without `jq` (falls back to a safe `printf` form) so it can
even report that `jq` itself is missing.

## Conformance

`test/contract_smoke.sh` is the gate: every script, on forced failure, must emit
parseable JSON with a non-empty `fix` and the correct exit code.
