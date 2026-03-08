defmodule Loomkin.Teams.AgentChildTeamsTest do
  use ExUnit.Case, async: false
  @moduletag :skip

  describe "spawned_child_teams field" do
    @tag :skip
    test "spawned_child_teams defaults to empty list" do
      assert false
    end

    @tag :skip
    test "receiving :child_team_spawned message adds team_id to spawned_child_teams" do
      assert false
    end
  end

  describe "terminate/2 child team dissolution" do
    @tag :skip
    test "terminate/2 calls Manager.dissolve_team for each spawned child team" do
      assert false
    end

    @tag :skip
    test "terminate/2 with no child teams completes without error" do
      assert false
    end
  end
end
