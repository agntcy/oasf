# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ApplicationTest do
  use ExUnit.Case, async: true

  alias Schema.Application

  describe "parse_extensions/1" do
    test "returns no extensions when unset" do
      assert Application.parse_extensions(nil) == []
    end

    test "returns no extensions when blank" do
      assert Application.parse_extensions("") == []
      assert Application.parse_extensions("   ") == []
      assert Application.parse_extensions(" , ,") == []
    end

    test "splits and trims a comma-separated list" do
      assert Application.parse_extensions("extensions") == ["extensions"]

      assert Application.parse_extensions(" extensions , /abs/ext,,") == [
               "extensions",
               "/abs/ext"
             ]
    end
  end
end
