defmodule Loomkin.AgentLoop.Checkpoint do
  @moduledoc """
  Represents a checkpoint during agent loop execution.

  Checkpoints allow external observers (e.g. the Agent GenServer) to inspect
  what the agent is about to do (`:post_llm`) or just did (`:post_tool`), and
  optionally pause execution.

  The checkpoint callback receives a `%Checkpoint{}` and returns either
  `:continue` or `{:pause, reason}`.
  """

  @type checkpoint_type :: :post_llm | :post_tool

  @type t :: %__MODULE__{
          type: checkpoint_type(),
          agent_name: String.t() | atom() | nil,
          team_id: String.t() | nil,
          iteration: non_neg_integer(),
          planned_tools: [map()] | nil,
          tool_name: String.t() | nil,
          tool_result: String.t() | nil,
          messages: [map()]
        }

  defstruct [
    :type,
    :agent_name,
    :team_id,
    :iteration,
    :planned_tools,
    :tool_name,
    :tool_result,
    messages: []
  ]
end
