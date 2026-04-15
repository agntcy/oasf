# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.LayoutViewTest do
  use ExUnit.Case, async: true

  alias SchemaWeb.LayoutView

  # ---------------------------------------------------------------------------
  # format_profile/1
  # ---------------------------------------------------------------------------

  describe "format_profile/1" do
    test "returns attribute names joined by newline" do
      profile = %{attributes: %{name: %{}, description: %{}}}
      result = LayoutView.format_profile(profile)
      assert is_binary(result)
      lines = String.split(result, "\n")
      assert "name" in lines or "description" in lines
    end

    test "returns empty string for profile with no attributes" do
      assert LayoutView.format_profile(%{attributes: %{}}) == ""
    end
  end

  # ---------------------------------------------------------------------------
  # format_extension/1
  # ---------------------------------------------------------------------------

  describe "format_extension/1" do
    test "returns caption and uid without version" do
      ext = %{caption: "My Extension", uid: 42}
      result = LayoutView.format_extension(ext)
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "My Extension")
      assert String.contains?(flat, "42")
      refute String.contains?(flat, "</br>")
    end

    test "includes version when present" do
      ext = %{caption: "My Extension", uid: 1, version: "2.0.0"}
      result = LayoutView.format_extension(ext)
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "2.0.0")
      assert String.contains?(flat, "</br>")
    end
  end
end
