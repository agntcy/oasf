# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ClassExportTest do
  @moduledoc """
  Guards the memory cost of the class list endpoints (/api/skills, /api/domains,
  /api/modules).

  Enriching a class merges each attribute's definition from the dictionary.  A
  dictionary attribute carries a `_links` back-reference to *every* class that
  uses it, so copying it into each of the hundreds of classes is O(n^2).  The
  enriched export is deep-copied out of the Repo Agent on every request, which
  materialized >100 MiB and OOM-killed the pod under concurrent list requests.
  Attribute `_links` are internal and stripped from every response, so they must
  never be built into enriched classes in the first place.
  """
  use ExUnit.Case, async: false

  test "enriched class attributes do not carry internal _links" do
    for family <- [:skill, :domain, :module] do
      Schema.Repo.classes(family)
      |> Enum.each(fn {_key, class} ->
        (class[:attributes] || [])
        |> Enum.each(fn {attr_name, attr} ->
          refute Map.has_key?(attr, :_links),
                 "#{family} attribute #{inspect(attr_name)} still carries _links"
        end)
      end)
    end
  end

  test "enriched skill export stays small (no O(n^2) _links blow-up)" do
    mib =
      Schema.Repo.classes(:skill)
      |> :erlang.term_to_binary()
      |> byte_size()
      |> Kernel./(1_048_576)

    assert mib < 5.0,
           "enriched skill export is #{Float.round(mib, 1)} MiB; expected < 5 MiB " <>
             "(dictionary _links are being copied into every class)"
  end
end
