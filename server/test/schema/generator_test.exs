# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.GeneratorTest do
  @moduledoc """
  Tests for sample data generation.

  The `record` object references the `skill`, `domain`, and `module` class
  families through `class_t` enum attributes.  Generating a sample must only
  materialize the handful of classes it actually samples — never the entire
  family — otherwise per-request memory scales with the taxonomy size and the
  server is OOM-killed under load (regression introduced by the granular
  skills/domains taxonomy).
  """
  use ExUnit.Case, async: false

  # Runs `fun` in a dedicated process and returns the reductions it consumed.
  # Reductions are a deterministic proxy for work done (independent of GC
  # timing), so they make a stable regression guard against re-materializing
  # the whole class family per sample.
  defp reductions(fun) do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        fun.()
        {:reductions, red} = Process.info(self(), :reductions)
        send(parent, {:reductions, red})
      end)

    receive do
      {:reductions, red} ->
        # Success: the reductions report is sent before the process exits, so it
        # is received before the :DOWN. Flush the pending :DOWN and return.
        Process.demonitor(ref, [:flush])
        red

      {:DOWN, ^ref, :process, ^pid, reason} ->
        flunk("sample generation process crashed: #{inspect(reason)}")
    after
      60_000 ->
        Process.demonitor(ref, [:flush])
        Process.exit(pid, :kill)
        flunk("sample generation timed out")
    end
  end

  describe "generate_object/2 for the record object" do
    test "produces valid, bounded skill/domain samples" do
      record = Schema.object(nil, "record")
      assert record, "record object must exist in the loaded schema"

      sample = Schema.generate_object(record, nil)

      skills = Map.get(sample, :skills) || Map.get(sample, "skills") || []
      assert is_list(skills)
      # The array generator caps skills at random(10); a sample must never emit
      # one entry per class in the (hundreds-strong) taxonomy.
      assert length(skills) <= 10

      # Each generated skill is a class instance (a map), not a bare id/name.
      Enum.each(skills, fn skill -> assert is_map(skill) end)
    end

    test "does not materialize the entire class family per sample" do
      record = Schema.object(nil, "record")

      red = reductions(fn -> Schema.generate_object(record, nil) end)

      # Before the fix, generating one record sample materialized every skill
      # (~500) and domain (~180) via an O(n^2) reverse lookup, costing ~7-8M
      # reductions.  Selecting candidates lazily keeps it well under this bound.
      assert red < 2_000_000,
             "record sample used #{red} reductions; expected < 2_000_000 " <>
               "(the whole class family is being materialized per sample)"
    end
  end
end
