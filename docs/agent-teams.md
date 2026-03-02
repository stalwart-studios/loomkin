# Agent Teams

> Core complete, hardening in progress.

Loomkin's agent teams are built on OTP — the same infrastructure that keeps telecom switches running for decades. Each agent is a GenServer, communication is native message passing, and the whole system is supervised and fault-tolerant by design.

Every session is a team. A solo agent is a team of one that can auto-scale when the task demands it. Spawn a 10-agent team for ~$0.25 vs ~$4.50 with a single expensive model (18x savings).

## Core

- **OTP-native agent teams** — each agent is a GenServer under a DynamicSupervisor. Spawn in <500ms. Agents communicate through Phoenix PubSub in real-time — direct messages, team-wide broadcasts, context updates. No files, no polling, sub-millisecond latency. 100+ concurrent agents per node.
- **Zero-loss context mesh** — agents offload context to lightweight Keeper processes instead of summarizing it away. Nothing is ever destroyed — any agent can retrieve the full conversation from any other agent's history. Smart retrieval uses cheap LLM calls to semantically search keeper contents, not just dump raw chunks. 228K+ tokens preserved vs 128K single-process window.
- **5 built-in roles** — lead, researcher, coder, reviewer, tester. Each role has scoped tools and a tailored system prompt. Custom roles configurable via `.loomkin.toml` with custom tools, system prompts, and budget limits.
- **Region-level file locking** — multiple agents can safely edit the same file by claiming specific line ranges or symbols. Intent broadcasting lets peers coordinate before editing.
- **Async agent loops** — LLM calls run as `Task.async`, so agents stay responsive to messages even while waiting for model responses. Urgent messages (budget exceeded, file conflicts) can interrupt in-flight work.

## Coordination

- **Peer review protocol** — agents request code reviews from each other. Critical paths can require review before edits are applied.
- **Peer communication** — agents ask each other questions, forward queries to specialists, and share discoveries proactively. Query routing tracks hops and enriches answers.
- **Structured debate** — propose/critique/revise/vote cycle for complex decisions where multiple approaches are viable.
- **Pair programming** — dedicated coder + reviewer pairing with real-time event exchange for tight feedback loops.
- **Task coordination** — agents create tasks, propose plan revisions, and discover work that needs doing. Living plans evolve as the team learns.
- **Cross-session learning** — records task outcomes, recommends team compositions and model selections for future tasks based on historical performance.
- **Team templates** — save and load proven team configurations from `.loomkin.toml`.

## Budget & Observability

- **Per-team budget tracking** — token bucket rate limiting per provider, per-team and per-agent spend tracking with configurable limits. Real-time cost dashboard per team.
- **Model escalation** — cheap model fails twice → auto-escalate to next tier. Per-agent model selection enables cheap grunts + expensive judges.
- **Team orchestration dashboard** — LiveView team management UI with real-time agent status, task progress, activity feed, and cost tracking. Spawn controls, team switcher, and per-agent visibility.
- **Response streaming** — real-time streaming from team agents to the web UI. Agent activity feed streams tool execution and discoveries as they happen.
- **Permission system** — complete permission flow for team operations with approval modals and configurable auto-approve for team agents.

## Distributed

- **Horde-based clustering** — distributed supervisor and registry for multi-node deployments. Cross-node agent communication via distributed Erlang.

## Example: Refactoring a Module

Ask Loomkin to refactor a module and it automatically:

1. Spawns **researchers** to analyze usage patterns across the codebase
2. Spawns **coders** that claim specific file regions and implement changes in parallel
3. Spawns a **reviewer** that checks every edit before it's applied
4. Coordinates all of them through PubSub, with the decision graph tracking every choice
5. Any agent can ask the team a question, create new tasks, or propose plan revisions

## Configuration

Enable teams in your `.loomkin.toml`:

```toml
[teams]
enabled = true
max_agents_per_team = 10
max_concurrent_teams = 3

[teams.budget]
max_per_team_usd = 5.00
max_per_agent_usd = 1.00
```

See [configuration.md](configuration.md) for the full config reference.
