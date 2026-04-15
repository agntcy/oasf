# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.UtilsTest do
  use ExUnit.Case, async: true

  alias Schema.Utils

  # ---------------------------------------------------------------------------
  # parse_version/1
  # ---------------------------------------------------------------------------

  describe "parse_version/1" do
    test "parses a simple release version" do
      assert %{major: 1, minor: 2, patch: 3} = Utils.parse_version("1.2.3")
    end

    test "parses a version with prerelease" do
      result = Utils.parse_version("0.7.0-alpha.1")
      assert result[:major] == 0
      assert result[:minor] == 7
      assert result[:patch] == 0
      assert result[:prerelease] == "alpha.1"
    end

    test "parses a zero major version" do
      assert %{major: 0, minor: 0, patch: 1} = Utils.parse_version("0.0.1")
    end

    test "parses large version numbers" do
      assert %{major: 100, minor: 200, patch: 300} = Utils.parse_version("100.200.300")
    end

    test "returns error for malformed version (missing patch)" do
      assert {:error, "malformed", "1.2"} = Utils.parse_version("1.2")
    end

    test "returns error for malformed version (garbage string)" do
      assert {:error, "malformed", "not-a-version"} = Utils.parse_version("not-a-version")
    end

    test "returns error for empty string" do
      assert {:error, "malformed", ""} = Utils.parse_version("")
    end

    test "returns error for non-string input (integer)" do
      assert {:error, "not a string", 42} = Utils.parse_version(42)
    end

    test "returns error for non-string input (nil)" do
      assert {:error, "not a string", nil} = Utils.parse_version(nil)
    end

    test "returns error for non-string input (atom)" do
      assert {:error, "not a string", :foo} = Utils.parse_version(:foo)
    end

    test "does not include prerelease key when no prerelease segment" do
      result = Utils.parse_version("2.0.0")
      refute Map.has_key?(result, :prerelease)
    end
  end

  # ---------------------------------------------------------------------------
  # version_is_prerelease?/1
  # ---------------------------------------------------------------------------

  describe "version_is_prerelease?/1" do
    test "returns true for prerelease version" do
      v = Utils.parse_version("1.0.0-beta.1")
      assert Utils.version_is_prerelease?(v)
    end

    test "returns false for release version" do
      v = Utils.parse_version("1.0.0")
      refute Utils.version_is_prerelease?(v)
    end

    test "returns false for error tuple" do
      refute Utils.version_is_prerelease?({:error, "malformed", "bad"})
    end
  end

  # ---------------------------------------------------------------------------
  # version_is_initial_development?/1
  # ---------------------------------------------------------------------------

  describe "version_is_initial_development?/1" do
    test "returns true for 0.x.y" do
      v = Utils.parse_version("0.5.0")
      assert Utils.version_is_initial_development?(v)
    end

    test "returns false for 1.x.y" do
      v = Utils.parse_version("1.0.0")
      refute Utils.version_is_initial_development?(v)
    end

    test "returns false for error tuple" do
      refute Utils.version_is_initial_development?({:error, "malformed", "bad"})
    end
  end

  # ---------------------------------------------------------------------------
  # version_sorter/2
  # ---------------------------------------------------------------------------

  describe "version_sorter/2" do
    test "equal versions return true" do
      v = Utils.parse_version("1.2.3")
      assert Utils.version_sorter(v, v)
    end

    test "lower major sorts before higher major" do
      v1 = Utils.parse_version("1.0.0")
      v2 = Utils.parse_version("2.0.0")
      assert Utils.version_sorter(v1, v2)
      refute Utils.version_sorter(v2, v1)
    end

    test "lower minor sorts before higher minor (same major)" do
      v1 = Utils.parse_version("1.1.0")
      v2 = Utils.parse_version("1.2.0")
      assert Utils.version_sorter(v1, v2)
    end

    test "lower patch sorts before higher patch (same major.minor)" do
      v1 = Utils.parse_version("1.0.1")
      v2 = Utils.parse_version("1.0.2")
      assert Utils.version_sorter(v1, v2)
    end

    test "prerelease sorts before release of same version" do
      pre = Utils.parse_version("1.0.0-alpha")
      rel = Utils.parse_version("1.0.0")
      assert Utils.version_sorter(pre, rel)
      refute Utils.version_sorter(rel, pre)
    end

    test "two prereleases are sorted lexicographically" do
      a = Utils.parse_version("1.0.0-alpha")
      b = Utils.parse_version("1.0.0-beta")
      assert Utils.version_sorter(a, b)
    end

    test "error tuples sort before valid versions" do
      err = {:error, "malformed", "bad"}
      v = Utils.parse_version("1.0.0")
      assert Utils.version_sorter(err, v)
      refute Utils.version_sorter(v, err)
    end

    test "two error tuples are sorted by original string" do
      e1 = {:error, "malformed", "aaa"}
      e2 = {:error, "malformed", "bbb"}
      assert Utils.version_sorter(e1, e2)
    end
  end

  # ---------------------------------------------------------------------------
  # make_path/2
  # ---------------------------------------------------------------------------

  describe "make_path/2" do
    test "returns name unchanged when extension is nil" do
      assert Utils.make_path(nil, "my_skill") == "my_skill"
    end

    test "joins extension and name with a path separator" do
      result = Utils.make_path("my_ext", "my_skill")
      assert result == "my_ext/my_skill"
    end
  end

  # ---------------------------------------------------------------------------
  # to_uid/1 and to_uid/2
  # ---------------------------------------------------------------------------

  describe "to_uid/1" do
    test "converts a binary to atom" do
      assert Utils.to_uid("foo") == :foo
    end

    test "returns atom unchanged" do
      assert Utils.to_uid(:foo) == :foo
    end
  end

  describe "to_uid/2" do
    test "returns name atom when extension is nil" do
      assert Utils.to_uid(nil, :my_skill) == :my_skill
    end

    test "builds scoped atom from extension and name" do
      uid = Utils.to_uid("ext", "skill")
      assert uid == :"ext/skill"
    end
  end

  # ---------------------------------------------------------------------------
  # deep_merge/2
  # ---------------------------------------------------------------------------

  describe "deep_merge/2" do
    test "merges two flat maps, right wins on conflict" do
      assert Utils.deep_merge(%{a: 1, b: 2}, %{b: 3, c: 4}) == %{a: 1, b: 3, c: 4}
    end

    test "recursively merges nested maps" do
      left = %{a: %{x: 1, y: 2}}
      right = %{a: %{y: 99, z: 3}}
      assert Utils.deep_merge(left, right) == %{a: %{x: 1, y: 99, z: 3}}
    end

    test "non-map value on right overwrites map on left" do
      left = %{a: %{x: 1}}
      right = %{a: "scalar"}
      assert Utils.deep_merge(left, right) == %{a: "scalar"}
    end

    test "nil left returns right" do
      assert Utils.deep_merge(nil, %{a: 1}) == %{a: 1}
    end

    test "nil right returns left" do
      assert Utils.deep_merge(%{a: 1}, nil) == %{a: 1}
    end

    test "nil both returns nil" do
      assert Utils.deep_merge(nil, nil) == nil
    end

    test "empty map on left defers to right" do
      assert Utils.deep_merge(%{a: %{}}, %{a: %{x: 1}}) == %{a: %{x: 1}}
    end

    test "empty map on right defers to left" do
      assert Utils.deep_merge(%{a: %{x: 1}}, %{a: %{}}) == %{a: %{x: 1}}
    end
  end

  # ---------------------------------------------------------------------------
  # sort_taxonomy_tree/1
  # ---------------------------------------------------------------------------

  describe "sort_taxonomy_tree/1" do
    test "sorts nodes by numeric id" do
      tree = %{
        b: %{id: 2, caption: "B"},
        a: %{id: 1, caption: "A"},
        c: %{id: 3, caption: "C"}
      }

      sorted = Utils.sort_taxonomy_tree(tree)
      ids = Enum.map(sorted, fn {_, node} -> node[:id] end)
      assert ids == [1, 2, 3]
    end

    test "sorts nested :classes recursively" do
      tree = %{
        cat: %{
          id: 1,
          classes: %{
            z: %{id: 30},
            a: %{id: 10}
          }
        }
      }

      [{:cat, node}] = Utils.sort_taxonomy_tree(tree)
      child_ids = Enum.map(node[:classes], fn {_, n} -> n[:id] end)
      assert child_ids == [10, 30]
    end

    test "returns empty list for non-map/list input" do
      assert Utils.sort_taxonomy_tree("bad") == []
    end

    test "handles string ids by parsing them as integers" do
      tree = %{b: %{id: "20"}, a: %{id: "5"}}
      sorted = Utils.sort_taxonomy_tree(tree)
      ids = Enum.map(sorted, fn {_, n} -> n[:id] end)
      assert ids == ["5", "20"]
    end
  end

  # ---------------------------------------------------------------------------
  # add_sibling_of_to_attributes/1
  # ---------------------------------------------------------------------------

  describe "add_sibling_of_to_attributes/1" do
    test "returns nil for nil input" do
      assert Utils.add_sibling_of_to_attributes(nil) == nil
    end

    test "adds _sibling_of back-reference to the target attribute (map input)" do
      attributes = %{
        type_id: %{sibling: "type", caption: "Type ID"},
        type: %{caption: "Type"}
      }

      result = Utils.add_sibling_of_to_attributes(attributes)
      assert result[:type][:_sibling_of] == :type_id
      refute Map.has_key?(result[:type_id], :_sibling_of)
    end

    test "adds _sibling_of back-reference (list of tuple input)" do
      attributes = [
        {:type_id, %{sibling: "type", caption: "Type ID"}},
        {:type, %{caption: "Type"}}
      ]

      result = Utils.add_sibling_of_to_attributes(attributes)
      type_attr = Keyword.get(result, :type)
      assert type_attr[:_sibling_of] == :type_id
    end

    test "does not modify attributes without siblings" do
      attributes = %{
        name: %{caption: "Name"},
        description: %{caption: "Description"}
      }

      result = Utils.add_sibling_of_to_attributes(attributes)
      refute Map.has_key?(result[:name], :_sibling_of)
      refute Map.has_key?(result[:description], :_sibling_of)
    end
  end

  # ---------------------------------------------------------------------------
  # put_non_nil/3
  # ---------------------------------------------------------------------------

  describe "put_non_nil/3" do
    test "puts key when value is not nil" do
      assert Utils.put_non_nil(%{}, :a, 1) == %{a: 1}
    end

    test "does not put key when value is nil" do
      assert Utils.put_non_nil(%{a: 1}, :b, nil) == %{a: 1}
    end
  end
end
