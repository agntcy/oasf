# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Profiles do
  @moduledoc """
  Profiles helper functions
  """

  require Logger

  @doc """
    Filter attributes based on a given set of profiles.
  """
  def apply_profiles(class, profiles) when is_list(profiles) do
    apply_profiles(class, MapSet.new(profiles))
  end

  def apply_profiles(class, %MapSet{} = profiles) do
    size = MapSet.size(profiles)

    Map.update!(class, :attributes, fn attributes ->
      apply_profiles(attributes, profiles, size)
    end)
    |> Map.update!(:objects, fn objects ->
      Enum.map(objects, fn {name, object} ->
        {name,
         Map.update!(object, :attributes, fn attributes ->
           apply_profiles(attributes, profiles, size)
         end)}
      end)
    end)
  end

  defp apply_profiles(attributes, _profiles, 0) do
    remove_profiles(attributes)
  end

  defp apply_profiles(attributes, profiles, _size) do
    Enum.filter(attributes, fn {_k, v} ->
      case v[:profile] do
        nil -> true
        profile -> MapSet.member?(profiles, profile)
      end
    end)
  end

  defp remove_profiles(attributes) do
    Enum.filter(attributes, fn {_k, v} -> Map.has_key?(v, :profile) == false end)
  end

  @doc """
    Checks items (classes or objects), ensuring that each all profiles defined in each item are
    defined in profiles. Adds each properly define profile to profile's _links.
  """
  def sanity_check(group, items, profiles) do
    Enum.reduce(items, profiles, fn {item_name, item}, acc ->
      check_profiles(group, item_name, item, item[:profiles], acc)
    end)
  end

  # Checks if all profile attributes are defined in the given attribute set.
  defp check_profiles(_group, _name, _map, nil, all_profiles) do
    all_profiles
  end

  defp check_profiles(group, item_name, item, item_profiles, all_profiles) do
    Enum.reduce(item_profiles, all_profiles, fn p, acc ->
      case acc[p] do
        nil ->
          Logger.warning("#{item_name} uses undefined profile: #{p}")
          acc

        profile ->
          link = Schema.Utils.make_link(group, item_name, item)
          profile = Map.update(profile, :_links, [link], fn links -> [link | links] end)
          Map.put(acc, p, profile)
      end
    end)
  end
end
