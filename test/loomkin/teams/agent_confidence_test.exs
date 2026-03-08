defmodule Loomkin.Teams.AgentConfidenceTest do
  use ExUnit.Case, async: true

  @moduletag :skip

  # alias Loomkin.Teams.Agent - will be used when tests are implemented

  describe "rate limit: first call" do
    @tag :skip
    test "rate limit: first AskUser call is allowed through" do
      assert false, "not implemented"
    end
  end

  describe "rate limit: batch on open card" do
    @tag :skip
    test "rate limit: second AskUser while card open appends to existing card" do
      assert false, "not implemented"
    end
  end

  describe "rate limit: drop within cooldown" do
    @tag :skip
    test "rate limit: second call within cooldown window when card is closed is dropped" do
      assert false, "not implemented"
    end
  end

  describe "rate limit: allow after cooldown" do
    @tag :skip
    test "rate limit: call after cooldown expires is allowed" do
      assert false, "not implemented"
    end
  end

  describe "rate limit: dropped call side effects" do
    @tag :skip
    test "rate limit: dropped call does not create a new card" do
      assert false, "not implemented"
    end
  end

  describe "batch answer routing" do
    @tag :skip
    test "batch: answers route to correct question by question_id" do
      assert false, "not implemented"
    end
  end

  describe "cooldown semantics" do
    @tag :skip
    test "cooldown: starts from when last question in batch is answered, not from card open" do
      assert false, "not implemented"
    end
  end
end
