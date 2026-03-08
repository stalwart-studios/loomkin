defmodule Loomkin.Tools.TeamSpawnTest do
  use ExUnit.Case, async: false
  @moduletag :skip

  describe "ChildTeamCreated signal not published from tool" do
    @tag :skip
    test "TeamSpawn.run/2 does not publish ChildTeamCreated after migration" do
      assert false
    end

    @tag :skip
    test "ChildTeamCreated is published exactly once by Manager.create_sub_team/3" do
      assert false
    end
  end
end
