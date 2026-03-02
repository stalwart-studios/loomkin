# Configuration

Loomkin is configured through a combination of `.loomkin.toml` files and environment variables.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API key | — |
| `OPENAI_API_KEY` | OpenAI API key | — |
| `GOOGLE_API_KEY` | Google AI API key | — |
| `LOOMKIN_DB_PATH` | SQLite database path | `~/.loomkin/loomkin.db` |
| `PORT` | Web UI port | `4200` |
| `SECRET_KEY_BASE` | Phoenix secret key | Derived from `$HOME` |

## `.loomkin.toml`

Create a `.loomkin.toml` in your project root to configure Loomkin per-project. Here's a fully annotated example:

```toml
# ── Model Selection ──────────────────────────────────────
[model]
default = "anthropic:claude-sonnet-4-6"     # primary model for all interactions
weak = "anthropic:claude-haiku-4-5"          # cheap model for summarization, commit messages
architect = "anthropic:claude-opus-4-6"      # strong model for architect mode planning
editor = "anthropic:claude-haiku-4-5"        # fast model for architect mode execution

# ── Permissions ──────────────────────────────────────────
[permissions]
# Tools listed here skip the approval prompt
auto_approve = ["file_read", "file_search", "content_search", "directory_list"]

# ── Context Window Budgets ───────────────────────────────
[context]
max_repo_map_tokens = 2048                   # tokens reserved for repo map
max_decision_context_tokens = 1024           # tokens reserved for decision graph context
reserved_output_tokens = 4096                # tokens reserved for model output

# ── Decision Graph ───────────────────────────────────────
[decisions]
enabled = true                               # enable decision graph tracking
enforce_pre_edit = false                      # require decision log before file edits
auto_log_commits = true                      # auto-log git commits to the graph

# ── MCP (Model Context Protocol) ────────────────────────
[mcp]
server_enabled = true                        # expose Loomkin tools via MCP to editors
servers = [                                  # external MCP servers to connect to
  { name = "tidewave", command = "mix", args = ["tidewave.server"] },
  { name = "hexdocs", url = "http://localhost:3001/sse" }
]

# ── LSP (Language Server Protocol) ───────────────────────
[lsp]
enabled = true
servers = [
  { name = "elixir-ls", command = "elixir-ls", args = [] }
]

# ── Repository Intelligence ──────────────────────────────
[repo]
watch_enabled = true                         # auto-refresh index on file changes

# ── Agent Teams ──────────────────────────────────────────
[teams]
enabled = true
max_agents_per_team = 10
max_concurrent_teams = 3

[teams.budget]
max_per_team_usd = 5.00                      # maximum spend per team
max_per_agent_usd = 1.00                     # maximum spend per agent
```

## `.loomkin.toml.example`

A minimal starter config ships with the repo at `.loomkin.toml.example`. Copy it to get started:

```bash
cp .loomkin.toml.example .loomkin.toml
```

## Project Rules (`LOOMKIN.md`)

In addition to `.loomkin.toml`, you can create a `LOOMKIN.md` in your project root to give Loomkin persistent natural-language instructions:

```markdown
# Project Instructions

This is a Phoenix LiveView app using Ecto with PostgreSQL.

## Rules
- Always run `mix format` after editing .ex files
- Run `mix test` before committing
- Use `binary_id` for all primary keys

## Allowed Operations
- Shell: `mix *`, `git *`, `elixir *`
- File Write: `lib/**`, `test/**`, `priv/repo/migrations/**`
- File Write Denied: `config/runtime.exs`, `.env*`
```
