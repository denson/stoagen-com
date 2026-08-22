# Orchestrator background-dispatch hygiene (Arc 24) — instruction module

> Relocated from `MAJOR_PLINY.md` §5.8 (CONDITIONAL — read on a `run_in_background` Agent dispatch
> or a background `Bash` task needing in-chat status). Provenance: debloat Arc 48 cut
> `agents/design/arc-48/design-rev1.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`.
> The slim-core residue is the §5.8 stub + routing-map row (`run_in_background` Agent fire) +
> relocation-index row in §4.2. **This module is the canonical home for the bw-poll-loop template**
> (`background-dispatch-hygiene.md` §5.8.3); op-disc §18 cites `MAJOR_PLINY.md` §5.8, which resolves
> top-level to the slim-core stub that points here. At subproject tier the body re-inlines into the
> deployed `MAJOR_PLINY` at its `<!-- MODULE-INLINE:background-dispatch-hygiene -->` marker.

When you dispatch a CAPTAIN via `Agent({ run_in_background: true, ... })`, or when you fire a background `Bash` task that needs in-chat status surfaced as it runs, follow this canonical sequence. The discipline closes the orchestrator side of the closed loop whose CAPTAIN side is the heartbeat-and-read-before-write discipline in every CAPTAIN role file. Universal-team framing: `operating-disciplines.md` §18.

## 5.8.1 Step 1 — At session start: load deferred tools

`ToolSearch` with `select:TaskStop,Monitor,PushNotification` at session start (or first time the orchestrator needs them). This loads their schemas into your context so subsequent invocations work without per-call schema fetches.

`TaskOutput` is **not loaded** by default — deprecated per its own tool description. Do not load it unless a specific legacy bash-polling use case requires it (rare).

## 5.8.2 Step 2 — At dispatch time: fire Agent + capture task_id + materialize to bw + start Monitor

```
# 1. Fire the Agent in background.
task_result = Agent({ run_in_background: true, ... })
# captures task_id from the returned <task-notification>

# 2. Materialize task_id to bw immediately.
bw comment <dispatch-ticket> "Dispatched <CAPTAIN> at <timestamp>. task_id=<id>. Brief: <link or summary>."

# 3. Start the persistent Monitor that polls bw for new comments.
Monitor({
  command: <canonical bw-poll loop, see §5.8.3 below>,
  description: "watching <CAPTAIN> heartbeats on <dispatch-ticket>",
  persistent: true
})
```

**The `Agent` return footer references `SendMessage` — disregard it.** Every `Agent` return ends with a footer instructing you to use `SendMessage` to "continue this agent." That mechanism is not part of the Stoa coordination model and is not callable in this environment. Capture the `task_id`; ignore the `SendMessage` reference entirely. There is no "continuing" a returned agent — to carry work forward, dispatch a fresh agent with a cold-pickup brief pointed at the bw + artifact state. Full framing: `operating-disciplines.md` §18.6.

The `task_id` materialization is mandatory at dispatch time. No tool enumerates running background tasks ([issue #29011](https://github.com/anthropics/claude-code/issues/29011), [issue #49140](https://github.com/anthropics/claude-code/issues/49140)); without the bw write at dispatch time, the `task_id` is structurally unrecoverable later in the session.

## 5.8.3 Step 3 — Canonical bw-poll loop (substrate-canonical template)

```bash
last=$(date -u +%Y-%m-%dT%H:%M:%SZ)
while true; do
  bw show <dispatch-ticket> --json 2>/dev/null \
    | SINCE="$last" python -c "
import sys, json, os
since = os.environ['SINCE']
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for c in d.get('comments', []):
    if c.get('timestamp', '') > since:
        text = c.get('text', '')
        print('[' + c.get('timestamp', '') + '] ' + text[:300].replace('\n', ' '))
" || true
  last=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  sleep 30
done
```

Each new bw comment by the CAPTAIN (or anyone else writing to the dispatch ticket) becomes a stdout line; `Monitor` emits it as an in-chat notification. The orchestrator reads `bw show` for full content when the notification fires. The `|| true` clause prevents transient `bw show` failures (network, lock contention) from killing the monitor mid-engagement.

**The bw JSON schema and the seat-identity convention.** `bw show <id> --json` exposes per-comment `{text, timestamp}` only — no `author` field. The seat identity is carried by the canonical first heartbeat (`"<SEAT> activated on <ticket>"` per the CAPTAIN heartbeat-and-read-before-write discipline) and every subsequent state heartbeat. The stdout line shape is `[<ISO-8601 timestamp>] <comment text, truncated to 300 chars, newlines flattened>`. Truncation at 300 chars is the in-chat notification-friendly bound; the orchestrator reads `bw show` directly for full content when context warrants.

**Why python, not jq.** `jq` is not a universal substrate-tier dependency (empirically absent on Windows Git Bash deployments). Python is, because `bw` itself is python-implemented — every machine that can run `bw` can run `python`. The `--json` contract is the stable parse surface; non-JSON `bw show` output is human-formatted and not a substrate-stable contract.

This template is the substrate-canonical version. MAJOR_POLYBIUS.md §7.6 cross-references it for the rare cases POLYBIUS dispatches CAPTAINs via the `Agent` tool directly. Do NOT invent a per-dispatch variant; copy the template and substitute the dispatch ticket ID.

## 5.8.4 Step 4 — On CAPTAIN completion: TaskStop the Monitor + read verdict

```
# Wait for the Agent's completion notification (automatic; no polling needed).
# When the notification fires:
TaskStop(<Monitor's task_id>)  # tear down the watcher
# Read the Agent's tool result for the verdict (NOT the .output file).
# Comment the verdict outcome on the parent epic.
```

**Never call `TaskOutput` on a `local_agent` task_id.** `.output` is a symlink to the full sub-agent conversation transcript (JSONL) and overflows the orchestrator's context. For Bash background tasks, `Read` on the output file is the safe path; `TaskOutput` itself remains deprecated.

## 5.8.5 Step 5 — PushNotification is orthogonal

For events PRINCIPAL needs to act on out-of-band — ship/no-ship verdict ready, blocker requiring human judgment, escalation — fire `PushNotification`. This is **orthogonal** to the orchestrator-CAPTAIN bridge; the bridge uses `Monitor` + bw, not `PushNotification`.

## 5.8.6 Locked decisions (B1-B6 from `stoa--nvl`)

| ID | Decision |
|---|---|
| B1 | `TaskOutput` forbidden on Agent dispatches (symlink to JSONL transcript overflows context) |
| B2 | `Monitor` is the canonical orchestrator push channel (not poll-cron, not ad-hoc bw poll inside the conversation) |
| B3 | `task_id` materialization to bw is mandatory at dispatch time (no enumeration tool exists) |
| B4 | Canonical poll-loop template lives in this module; copy per-dispatch with the ticket ID substituted |
| B5 | CAPTAIN-side `Monitor` and `run_in_background: true` Bash are forbidden (re-stated from `stoa--odh` A5) |
| B6 | `PushNotification` is reserved for PRINCIPAL-actionable events only |

## 5.8.7 Anthropic-side facts (as of 2026-05-12)

- **`Monitor` tool** ([release v2.1.98 on 2026-04-09](https://code.claude.com/docs/en/whats-new/2026-w15)) — shell command whose stdout streams as in-chat notifications. Persistent mode available.
- **`TaskStop` tool** — stops a running background task by `task_id`. Orchestrator can call; CAPTAINs cannot ([issue #23154](https://github.com/anthropics/claude-code/issues/23154)).
- **`TaskOutput`** — deprecated. Agent `.output` is the JSONL transcript symlink.
- **`PushNotification`** — orthogonal user-actionable push.
- **No enumeration tool exists** for running background tasks (issues #29011, #49140).
- **`SendMessage` / agent "continue"** — referenced by the `Agent` tool description and every `Agent` return footer; NOT part of the Stoa coordination model and not callable in this environment. Disregard the reference; carry work forward by dispatching fresh per §5.8.2 + `operating-disciplines.md` §18.6.
- **Subagents cannot run `TaskStop`** (issue #23154) — orphan-bug surface; basis for CAPTAIN-side prohibitions.

## 5.8.8 Empirical anchor

2026-05-12 ariadne PLINY incident — `Agent` dispatch of ADA mid-corpus-authoring without `Monitor` + task_id materialization led to a state-blind orchestrator and a confabulated assertion (verb-level failure captured at `operating-disciplines.md` §19). This section is the structural fix. Anchor: `stoa--nvl` (Arc 24 `stoa--cm3`). Recover via `bw show stoa--nvl`.
