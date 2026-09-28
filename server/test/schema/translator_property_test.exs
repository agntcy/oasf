# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.TranslatorPropertyTest do
  @moduledoc """
  Property-based tests for the record translator.

  `POST /api/translate/*` passes caller-supplied JSON to
  `Schema.Translator.translate/3`, so these properties cover the contract the
  HTTP layer relies on: non-maps come back untouched, maps come back as maps,
  and the result can be serialised into the response body.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  @families [:skill, :domain, :module, :object]

  # See the note in Schema.ValidatorPropertyTest: attribute names come from a
  # fixed pool so the generated values exercise real attribute definitions.
  @keys ~w(
    id name uid class_uid metadata description caption version
    attributes profiles extends category type object_type unknown_key
  )

  defp json_leaf do
    one_of([
      integer(),
      boolean(),
      float(),
      string(:printable, max_length: 24),
      constant(nil)
    ])
  end

  defp json_value do
    tree(json_leaf(), fn child ->
      one_of([
        list_of(child, max_length: 4),
        map_of(member_of(@keys), child, max_length: 4)
      ])
    end)
  end

  property "translate/3 returns non-map input unchanged" do
    check all(
            input <- one_of([integer(), string(:printable), boolean(), list_of(integer())]),
            family <- member_of(@families)
          ) do
      assert Schema.Translator.translate(input, [], family) == input
    end
  end

  property "translate/3 returns a JSON-encodable map for arbitrary objects" do
    check all(
            input <- map_of(member_of(@keys), json_value(), max_length: 6),
            family <- member_of(@families),
            max_runs: 200
          ) do
      result = Schema.Translator.translate(input, [], family)

      assert is_map(result)
      assert is_binary(Jason.encode!(result))
    end
  end

  property "translate/3 tolerates a declared class alongside arbitrary attributes" do
    check all(
            input <- map_of(member_of(@keys), json_value(), max_length: 6),
            max_runs: 200
          ) do
      result = Schema.Translator.translate(Map.put(input, "id", 10101), [], :skill)

      assert is_map(result)
      assert is_binary(Jason.encode!(result))
    end
  end
end
