# Why Elixir?

Most AI coding tools are built in Python or TypeScript. Loomkin is built in Elixir because the BEAM virtual machine is quietly the best runtime for AI agent workloads — and especially for agent *teams*.

## Why the BEAM for AI Agents

**Concurrency without complexity.** An AI agent that reads files, searches code, runs shell commands, and calls LLMs is inherently concurrent. On the BEAM, each tool execution is a lightweight process. Parallel tool calls aren't a threading nightmare — they're just `Task.async_stream`. No thread pools, no callback hell, no GIL.

**Fault tolerance is built in.** When a shell command hangs or an LLM provider times out, OTP supervisors handle it. A crashed tool doesn't take down the session. A crashed session doesn't take down the application. This isn't defensive coding — it's how the BEAM works.

**LiveView for real-time UI.** No other AI coding assistant offers a real-time web UI with streaming chat, file browsing, diff viewing, and decision graph visualization — without writing a single line of JavaScript. Phoenix LiveView makes this possible. The same session GenServer that powers the CLI powers the web UI. Two interfaces, one source of truth.

**Hot code reloading.** Update Loomkin's tools, add new providers, tweak the system prompt — all without restarting sessions or losing conversation state. In production. While agents are running.

**Pattern matching for LLM responses.** Elixir's pattern matching makes handling the zoo of LLM response formats (tool calls, streaming chunks, error variants, provider-specific quirks) clean and exhaustive rather than a tangle of if/else:

```elixir
# This is real code from Loomkin's agent loop
case ReqLLM.Response.classify(response) do
  %{type: :tool_calls} -> execute_tools_and_continue(response, state)
  %{type: :final_answer} -> persist_and_return(response, state)
  %{type: :error} -> handle_error(response, state)
end
```

## Why Agent Teams Specifically Belong on the BEAM

Most multi-agent AI systems bolt coordination onto single-threaded runtimes using message queues, file-based communication, or HTTP polling. Loomkin doesn't need any of that — the BEAM was literally built for this.

**Every agent is a GenServer.** Spawning an agent is `DynamicSupervisor.start_child/2`. It takes milliseconds, not seconds. An agent crashing doesn't take down the team — OTP supervisors restart it with its last known state. This is the same infrastructure that keeps telecom switches running for decades.

**Communication is native message passing.** Agents talk to each other through Phoenix PubSub — direct messages, team-wide broadcasts, context updates, task assignments. No serialization overhead, no network hops, no message broker to maintain. A PubSub broadcast reaches every agent in under a millisecond.

**Context never gets destroyed.** This is the big one. Every other AI coding tool summarizes or compacts conversation history as it grows, permanently losing information. Loomkin agents offload context to lightweight Keeper processes — GenServers that hold conversation chunks at full fidelity. Any agent can query any keeper to retrieve exactly what was said 200 messages ago. The context mesh means the team's collective memory grows with the task instead of shrinking.

**Cheap models, collective intelligence.** A swarm of affordable models (like GLM-5 at ~$0.95/M tokens) communicating fluidly through OTP can outperform a single expensive model working alone. When every agent has access to the team's shared knowledge, peer review, and real-time coordination, individual model capability matters less than collective capability. The same task that costs $5 with a single Opus call can cost $0.50 with a coordinated team.

## The Refactoring Example

Ask Loomkin to refactor a module and it automatically:

1. Spawns **researchers** to analyze usage patterns across the codebase
2. Spawns **coders** that claim specific file regions and implement changes in parallel
3. Spawns a **reviewer** that checks every edit before it's applied
4. Coordinates all of them through PubSub, with the decision graph tracking every choice
5. Any agent can ask the team a question, create new tasks, or propose plan revisions

This isn't a roadmap — the OTP infrastructure, agent communication, task coordination, and context mesh are built and working.
