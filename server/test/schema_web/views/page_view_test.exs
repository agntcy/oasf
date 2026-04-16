# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.PageViewTest do
  use ExUnit.Case, async: true

  alias SchemaWeb.PageView

  # ---------------------------------------------------------------------------
  # get_applicable_profiles/2
  # ---------------------------------------------------------------------------

  describe "get_applicable_profiles/2" do
    test "returns empty list when data has no profiles key" do
      assert PageView.get_applicable_profiles(%{}, %{"sec" => %{}}) == []
    end

    test "returns empty list when data profiles is empty" do
      assert PageView.get_applicable_profiles(%{profiles: []}, %{"sec" => %{}}) == []
    end

    test "filters out profiles not in the profiles map" do
      data = %{profiles: ["sec", "unknown"]}
      profiles = %{"sec" => %{caption: "Security"}}
      result = PageView.get_applicable_profiles(data, profiles)
      assert result == ["sec"]
    end

    test "returns all matching profiles" do
      data = %{profiles: ["sec", "net"]}
      profiles = %{"sec" => %{}, "net" => %{}}
      result = PageView.get_applicable_profiles(data, profiles)
      assert Enum.sort(result) == ["net", "sec"]
    end
  end

  # ---------------------------------------------------------------------------
  # format_applicable_profiles_json/1
  # ---------------------------------------------------------------------------

  describe "format_applicable_profiles_json/1" do
    test "returns '[]' for empty list" do
      assert PageView.format_applicable_profiles_json([]) == "[]"
    end

    test "returns JSON array string for single profile" do
      assert PageView.format_applicable_profiles_json(["sec"]) == ~s(["sec"])
    end

    test "returns JSON array string for multiple profiles" do
      result = PageView.format_applicable_profiles_json(["sec", "net"])
      assert result == ~s(["sec","net"])
    end
  end

  # ---------------------------------------------------------------------------
  # format_profiles/1
  # ---------------------------------------------------------------------------

  describe "format_profiles/1" do
    test "returns empty string for nil" do
      assert PageView.format_profiles(nil) == ""
    end

    test "returns data-profiles iodata for list" do
      result = PageView.format_profiles(["sec", "net"])
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "data-profiles=")
      assert String.contains?(flat, "sec")
      assert String.contains?(flat, "net")
    end
  end

  # ---------------------------------------------------------------------------
  # indent_class/1
  # ---------------------------------------------------------------------------

  describe "indent_class/1" do
    test "returns indent-level-0 for id 0" do
      assert PageView.indent_class(%{id: 0}) == "indent-level-0"
    end

    test "returns indent-level-0 for nil id" do
      assert PageView.indent_class(%{}) == "indent-level-0"
    end

    test "returns positive indent level for multi-digit ids" do
      result = PageView.indent_class(%{id: 10101})
      assert String.starts_with?(result, "indent-level-")
    end
  end

  # ---------------------------------------------------------------------------
  # format_caption/2
  # ---------------------------------------------------------------------------

  describe "format_caption/2" do
    test "returns field caption when present" do
      result = PageView.format_caption("fallback", %{caption: "My Caption"})
      assert String.contains?(IO.iodata_to_binary(result), "My Caption")
    end

    test "falls back to name when no caption" do
      result = PageView.format_caption("my_name", %{})
      assert IO.iodata_to_binary(result) == "my_name"
    end

    test "appends uid when present" do
      result = PageView.format_caption("name", %{caption: "Cap", uid: 42})
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "42")
    end

    test "appends id when present (new format)" do
      result = PageView.format_caption("name", %{caption: "Cap", id: 99})
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "99")
    end

    test "appends extension indicator when extension is set" do
      result = PageView.format_caption("name", %{caption: "Cap", extension: "myext"})
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "myext")
    end
  end

  # ---------------------------------------------------------------------------
  # format_linked_class_caption/3
  # ---------------------------------------------------------------------------

  describe "format_linked_class_caption/3" do
    test "returns anchor tag with class name" do
      result = PageView.format_linked_class_caption("/skills/foo", "foo", %{caption: "Foo"})
      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "<a href=")
      assert String.contains?(flat, "/skills/foo")
    end

    test "adds deprecated marker for deprecated classes" do
      result =
        PageView.format_linked_class_caption("/x", "x", %{caption: "X", deprecated: true})

      flat = IO.iodata_to_binary(result)
      assert String.contains?(flat, "Deprecated")
    end

    test "no deprecated marker for normal classes" do
      result = PageView.format_linked_class_caption("/x", "x", %{caption: "X"})
      flat = IO.iodata_to_binary(result)
      refute String.contains?(flat, "Deprecated")
    end
  end
end
