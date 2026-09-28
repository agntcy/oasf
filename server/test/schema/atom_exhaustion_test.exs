# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.AtomExhaustionTest do
  # Lookup names and request bodies are attacker-controlled on the public API,
  # which has neither authentication nor rate limiting. Converting them with
  # `String.to_atom/1` grows the atom table, which the VM never reclaims, until
  # it aborts. These paths must resolve without creating atoms.
  use ExUnit.Case, async: false

  defp unique(prefix) do
    "#{prefix}_#{System.unique_integer([:positive])}_#{:rand.uniform(9_999_999)}"
  end

  # Warm up first so lazily-loaded modules are not counted against the body.
  defp atoms_created(fun) do
    fun.()
    before = :erlang.system_info(:atom_count)
    fun.()
    :erlang.system_info(:atom_count) - before
  end

  test "object lookups with unknown names create no atoms" do
    assert atoms_created(fn ->
             for _ <- 1..200, do: assert(Schema.object(unique("obj")) == nil)
           end) == 0
  end

  test "class lookups with unknown names create no atoms" do
    for family <- [:skill, :domain, :module] do
      assert atoms_created(fn ->
               for _ <- 1..200, do: assert(Schema.class(family, unique("cls")) == nil)
             end) == 0
    end
  end

  test "validating unknown attribute names creates no atoms" do
    assert atoms_created(fn ->
             for _ <- 1..200 do
               Schema.Validator.validate(%{"id" => 10101, unique("attr") => "x"}, [], :skill)
             end
           end) == 0
  end

  test "validating unknown enum values creates no atoms" do
    assert atoms_created(fn ->
             for _ <- 1..200 do
               Schema.Validator.validate(%{"id" => 10101, "name" => unique("val")}, [], :skill)
             end
           end) == 0
  end

  test "translating unknown attribute names creates no atoms" do
    assert atoms_created(fn ->
             for _ <- 1..200 do
               Schema.Translator.translate(%{"id" => 10101, unique("attr") => "x"}, [], :skill)
             end
           end) == 0
  end

  test "known names still resolve" do
    {object_name, _} = Schema.all_objects() |> Enum.at(0)
    assert Schema.object(Atom.to_string(object_name)) != nil

    {class_name, _} =
      Schema.all_classes(:skill) |> Enum.find(fn {_k, v} -> v[:category] != true end)

    assert Schema.class(:skill, Atom.to_string(class_name)) != nil
  end
end
