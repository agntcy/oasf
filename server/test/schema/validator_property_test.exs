# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ValidatorPropertyTest do
  @moduledoc """
  Property-based tests for the record validator.

  `POST /api/validate/{skill,domain,module}` and `/api/validate/object/:name`
  hand arbitrary caller-supplied JSON to `Schema.Validator.validate/3`, so the
  properties here are the ones the HTTP layer depends on: the call returns, the
  counts describe the lists they summarise, and the response can actually be
  serialised into the response body.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  @families [:skill, :domain, :module, :object]

  # Attribute names are drawn from a fixed pool rather than generated. Random
  # names would explore nothing extra here -- the validator treats every unknown
  # name the same way -- while the schema-defined names below are the ones that
  # reach the type, enum and constraint checks.
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

  defp json_object do
    map_of(member_of(@keys), json_value(), max_length: 6)
  end

  property "validate/3 returns a well-formed response for arbitrary input" do
    check all(
            input <- json_object(),
            family <- member_of(@families),
            max_runs: 200
          ) do
      response = Schema.Validator.validate(input, [], family)

      assert is_map(response)
      assert is_list(response[:errors])
      assert is_list(response[:warnings])
      assert response[:error_count] == length(response[:errors])
      assert response[:warning_count] == length(response[:warnings])
    end
  end

  property "validate/3 responses are always JSON-encodable" do
    # The response is assembled from caller-supplied values and then written
    # straight into the HTTP body, so a term that survives sanitisation without
    # being encodable is a 500 rather than a validation error.
    check all(
            input <- json_object(),
            family <- member_of(@families),
            max_runs: 200
          ) do
      response = Schema.Validator.validate(input, [], family)
      assert is_binary(Jason.encode!(response))
    end
  end

  property "validate/3 tolerates a declared class alongside arbitrary attributes" do
    # Supplying a real class id gets past the class lookup, so generated values
    # are checked against real attribute definitions rather than rejected early.
    check all(input <- json_object(), max_runs: 200) do
      response = Schema.Validator.validate(Map.put(input, "id", 10101), [], :skill)

      assert is_map(response)
      assert is_integer(response[:error_count])
      assert is_binary(Jason.encode!(response))
    end
  end
end
