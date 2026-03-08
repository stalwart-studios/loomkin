defmodule Loomkin.Teams.AgentStateMachineTest do
  use ExUnit.Case, async: false

  alias Loomkin.Teams.Agent

  defp unique_team_id do
    "test-team-#{:erlang.unique_integer([:positive])}"
  end

  defp start_agent(overrides \\ []) do
    team_id = Keyword.get(overrides, :team_id, unique_team_id())
    name = Keyword.get(overrides, :name, "agent-#{:erlang.unique_integer([:positive])}")
    role = Keyword.get(overrides, :role, :coder)

    opts =
      [team_id: team_id, name: name, role: role]
      |> Keyword.merge(overrides)

    {:ok, pid} = start_supervised({Agent, opts}, id: {team_id, name})
    %{pid: pid, team_id: team_id, name: name, role: role}
  end

  describe "pause_queued field" do
    test "defaults to false in struct" do
      %{pid: pid} = start_agent()
      state = :sys.get_state(pid)
      assert state.pause_queued == false
    end
  end

  describe "request_pause guards" do
    test "sets pause_requested when status is :working" do
      %{pid: pid} = start_agent()
      :sys.replace_state(pid, fn s -> %{s | status: :working} end)

      Agent.request_pause(pid)
      :timer.sleep(50)

      state = :sys.get_state(pid)
      assert state.pause_requested == true
      assert state.pause_queued == false
    end

    test "queues pause when status is :waiting_permission" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{s | status: :waiting_permission, pending_permission: %{some: :data}}
      end)

      Agent.request_pause(pid)
      :timer.sleep(50)

      state = :sys.get_state(pid)
      assert state.pause_queued == true
      assert state.pause_requested == false
    end

    test "no-op when status is :idle" do
      %{pid: pid} = start_agent()
      state_before = :sys.get_state(pid)
      assert state_before.status == :idle

      Agent.request_pause(pid)
      :timer.sleep(50)

      state_after = :sys.get_state(pid)
      assert state_after.pause_requested == false
      assert state_after.pause_queued == false
    end

    test "queues pause when status is :approval_pending" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{s | status: :approval_pending}
      end)

      Agent.request_pause(pid)
      :timer.sleep(50)

      state = :sys.get_state(pid)
      assert state.pause_queued == true
      assert state.pause_requested == false
    end
  end

  describe "permission_response with pause_queued" do
    test "auto-transitions to :paused when pause_queued is true" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{
          s
          | status: :waiting_permission,
            pause_queued: true,
            pending_permission: %{
              tool_name: "file_read",
              tool_path: "/tmp/test",
              pending_data: %{
                tool_module: Loomkin.Tools.FileRead,
                tool_args: %{},
                context: %{project_path: "/tmp"}
              }
            }
        }
      end)

      GenServer.cast(pid, {:permission_response, "allow_once", "file_read", "/tmp/test"})
      :timer.sleep(100)

      state = :sys.get_state(pid)
      assert state.status == :paused
      assert state.pause_queued == false
      assert state.pending_permission == nil
      assert state.paused_state != nil
      assert state.paused_state.reason == :user_requested
    end

    test "preserves denial context in paused_state when denied with pause_queued" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{
          s
          | status: :waiting_permission,
            pause_queued: true,
            pending_permission: %{
              tool_name: "shell",
              tool_path: "/usr/bin/rm",
              pending_data: %{
                tool_module: Loomkin.Tools.Shell,
                tool_args: %{},
                context: %{project_path: "/tmp"}
              }
            }
        }
      end)

      GenServer.cast(pid, {:permission_response, "deny", "shell", "/usr/bin/rm"})
      :timer.sleep(100)

      state = :sys.get_state(pid)
      assert state.status == :paused
      assert state.pause_queued == false

      assert state.paused_state.cancelled_permission == %{
               denied_tool: "shell",
               denied_path: "/usr/bin/rm"
             }
    end

    test "resumes work normally when pause_queued is false" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{
          s
          | status: :waiting_permission,
            pause_queued: false,
            pending_permission: %{
              tool_name: "file_read",
              tool_path: "/tmp/test",
              pending_data: %{
                tool_module: Loomkin.Tools.FileRead,
                tool_args: %{},
                context: %{project_path: "/tmp"}
              }
            }
        }
      end)

      GenServer.cast(pid, {:permission_response, "allow_once", "file_read", "/tmp/test"})
      :timer.sleep(100)

      state = :sys.get_state(pid)
      # Should NOT be paused -- normal flow continues
      assert state.pending_permission == nil
      assert state.pause_queued == false
      refute state.status == :paused
    end
  end

  describe "set_status_and_broadcast guards" do
    test "rejects direct transition from :waiting_permission to :paused" do
      %{pid: pid} = start_agent()

      :sys.replace_state(pid, fn s ->
        %{s | status: :waiting_permission, pending_permission: %{some: :data}}
      end)

      Agent.request_pause(pid)
      :timer.sleep(50)

      state = :sys.get_state(pid)
      # Must still be :waiting_permission, not :paused
      assert state.status == :waiting_permission
      assert state.pause_queued == true
    end
  end
end
