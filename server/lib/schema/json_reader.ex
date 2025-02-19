# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.JsonReader do
  @moduledoc """
    Provides functions to read, parse, merge json files, and resolving the included files.
  """
  use GenServer

  alias Schema.Utils

  require Logger

  # The default location of the schema file"schema"
  @categories_dir "categories"
  @domains_dir "domains"
  @objects_dir "objects"
  @profiles_dir "profiles"

  # The schema uses JSON files
  @schema_file ".json"

  # The Schema version file
  @version_file "version.json"

  @main_domains_file "main_domains.json"
  @dictionary_file "dictionary.json"

  # The Schema extension file
  @extension_file "extension.json"

  # The include directive
  @include :"$include"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec read_version() :: map()
  def read_version() do
    GenServer.call(__MODULE__, :read_version)
  end

  @spec read_categories(String.t()) :: map()
  def read_categories(categories_file) do
    GenServer.call(__MODULE__, {:read_categories, categories_file})
  end

  @spec read_main_domains() :: map()
  def read_main_domains() do
    GenServer.call(__MODULE__, :read_main_domains)
  end

  @spec read_dictionary() :: map()
  def read_dictionary() do
    GenServer.call(__MODULE__, :read_dictionary)
  end

  @spec read_objects() :: map()
  def read_objects() do
    GenServer.call(__MODULE__, :read_objects)
  end

  @spec read_classes() :: map()
  def read_classes() do
    GenServer.call(__MODULE__, :read_classes)
  end

  @spec read_domains() :: map()
  def read_domains() do
    GenServer.call(__MODULE__, :read_domains)
  end

  @spec read_profiles() :: map()
  def read_profiles() do
    GenServer.call(__MODULE__, :get_profiles)
  end

  @spec reset() :: :ok
  def reset() do
    GenServer.cast(__MODULE__, {:reset, []})
  end

  @spec reset(String.t()) :: :ok
  def reset(name) when is_binary(name) do
    GenServer.cast(__MODULE__, {:reset, [name]})
  end

  def reset(list) when is_list(list) do
    GenServer.cast(__MODULE__, {:reset, list})
  end

  @spec extensions :: any
  def extensions() do
    GenServer.call(__MODULE__, :extensions)
  end

  @spec cleanup() :: :ok
  def cleanup() do
    GenServer.cast(__MODULE__, :delete)
  end

  @impl true
  @spec init(list()) :: {:ok, term()}
  def init([schema_dir, ext_dir]) do
    init_cache()

    home = schema_home(schema_dir)
    version = read_version(home)
    extensions = read_extensions(home, ext_dir)

    Logger.info("schema    : #{home}")
    Logger.info("version   : #{version.version}")
    Logger.info("extensions: #{Jason.encode!(extensions, pretty: true)}")

    {:ok, {home, extensions}}
  end

  @impl true
  def handle_call(:read_version, _from, {home, _ext} = state) do
    {:reply, read_version(home), state}
  end

  @impl true
  def handle_call({:read_categories, categories_file}, _from, {home, ext} = state) do
    {:reply, read_categories(home, ext, categories_file), state}
  end

  @impl true
  def handle_call(:read_main_domains, _from, {home, ext} = state) do
    {:reply, read_main_domains(home, ext), state}
  end

  @impl true
  def handle_call(:read_dictionary, _from, {home, ext} = state) do
    {:reply, read_dictionary(home, ext), state}
  end

  @impl true
  def handle_call(:get_profiles, _from, state) do
    {:reply, get_profiles(), state}
  end

  @impl true
  def handle_call(:read_objects, _from, {home, ext} = state) do
    {:reply, read_objects(home, ext), state}
  end

  @impl true
  def handle_call(:read_classes, _from, {home, ext} = state) do
    {:reply, read_classes(home, ext), state}
  end

  @impl true
  def handle_call(:read_domains, _from, {home, ext} = state) do
    {:reply, read_domains(home, ext), state}
  end

  @impl true
  def handle_call(:extensions, _from, {_home, ext} = state) do
    extensions = Enum.into(ext, %{}, fn ext -> {ext[:name], ext} end)
    {:reply, extensions, state}
  end

  @impl true
  def handle_cast({:reset, ext}, {home, _ext}) do
    {:noreply, {home, read_extensions(home, ext)}}
  end

  @impl true
  def handle_cast(:delete, state) do
    delete()
    {:noreply, state}
  end

  defp schema_home(dir) do
    Path.absname(dir) |> Path.expand()
  end

  defp read_version(home) do
    file = Path.join(home, @version_file)

    if File.regular?(file) do
      read_json_file(file)
    else
      Logger.warning("version file #{file} not found")
      %{:version => "0.0.0"}
    end
  end

  defp read_categories(home, [], categories_file) do
    Path.join(home, categories_file) |> read_json_file()
  end

  defp read_categories(home, extensions, categories_file) do
    categories = Path.join(home, categories_file) |> read_json_file()

    Enum.reduce(extensions, categories, fn ext, acc ->
      merge_ext_file(acc, ext, categories_file)
    end)
  end

  defp read_main_domains(home, []) do
    Path.join(home, @main_domains_file) |> read_json_file()
  end

  defp read_main_domains(home, extensions) do
    main_domains = Path.join(home, @main_domains_file) |> read_json_file()

    Enum.reduce(extensions, main_domains, fn ext, acc ->
      merge_ext_file(acc, ext, @main_domains_file)
    end)
  end

  defp read_dictionary(home, []) do
    Path.join(home, @dictionary_file) |> read_json_file()
  end

  defp read_dictionary(home, extensions) do
    dictionary = Path.join(home, @dictionary_file) |> read_json_file()

    Enum.reduce(extensions, dictionary, fn ext, acc ->
      merge_ext_file(acc, ext, @dictionary_file)
    end)
  end

  def read_profiles(home, []) do
    read_schema_dir(Map.new(), home, Path.join(home, @profiles_dir))
    |> Enum.into(Map.new(), fn {name, profile} -> {Atom.to_string(name), profile} end)
  end

  def read_profiles(home, extensions) do
    profiles = read_schema_dir(Map.new(), home, Path.join(home, @profiles_dir))

    Enum.reduce(extensions, profiles, fn ext, acc ->
      read_extension_dir(acc, home, ext, @profiles_dir)
    end)
    |> Enum.into(%{}, fn {name, profile} -> {Atom.to_string(name), profile} end)
  end

  defp read_objects(home, []) do
    read_schema_dir(Map.new(), home, Path.join(home, @objects_dir))
  end

  defp read_objects(home, extensions) do
    objects = read_schema_dir(Map.new(), home, Path.join(home, @objects_dir))

    Enum.reduce(extensions, objects, fn ext, acc ->
      read_extension_dir(acc, home, ext, @objects_dir)
    end)
  end

  defp read_classes(home, []) do
    read_schema_dir(Map.new(), home, Path.join(home, @categories_dir))
  end

  defp read_classes(home, extensions) do
    events = read_schema_dir(Map.new(), home, Path.join(home, @categories_dir))

    Enum.reduce(extensions, events, fn ext, acc ->
      read_extension_dir(acc, home, ext, @categories_dir)
    end)
  end

  defp read_domains(home, []) do
    read_schema_dir(Map.new(), home, Path.join(home, @domains_dir))
  end

  defp read_domains(home, extensions) do
    events = read_schema_dir(Map.new(), home, Path.join(home, @domains_dir))

    Enum.reduce(extensions, events, fn ext, acc ->
      read_extension_dir(acc, home, ext, @domains_dir)
    end)
  end

  defp read_schema_dir(acc, home, path) do
    if File.dir?(path) do
      Logger.info("[] read files: #{path}")

      case File.ls(path) do
        {:ok, files} ->
          files
          |> Stream.map(fn file -> Path.join(path, file) end)
          |> Enum.reduce(acc, fn file, map -> read_schema_dir(map, home, file) end)

        error ->
          error("unable to access #{path} directory. Error: #{inspect(error)}")
      end
    else
      if Path.extname(path) == @schema_file do
        data = read_json_file(path) |> resolve_includes(home)
        Map.put(acc, String.to_atom(data[:name]), data)
      else
        acc
      end
    end
  end

  defp read_json_file(file) do
    case File.read(file) do
      {:ok, data} ->
        case Jason.decode(data, keys: :atoms) do
          {:ok, json} ->
            json

          {:error, error} ->
            message = Jason.DecodeError.message(error)
            error("invalid JSON file: #{file}. Error: #{message}")
        end

      {:error, :enoent} ->
        error("file #{file} does not exist")

      {:error, :eacces} ->
        error("missing permission for reading #{file} file")

      {:error, :eisdir} ->
        error("file #{file} is a directory")

      {:error, reason} ->
        error("unable to read #{file} file. Reason: #{reason}")
    end
  end

  # used by dictionary and categories
  defp merge_ext_file(acc, ext, file) do
    path = Path.join(ext[:path], file)

    if File.regular?(path) do
      Logger.debug("read ext file: [#{ext[:name]}] #{path}")

      ext_data = read_json_file(path)

      Map.update!(acc, :attributes, fn attributes ->
        ext_type = ext[:name]
        ext_uid = ext[:uid]

        Map.merge(
          attributes,
          Enum.into(ext_data[:attributes], %{}, fn {name, value} = attribute ->
            if value[:overwrite] == true do
              case attributes[name] do
                nil ->
                  attribute

                a ->
                  {name, Map.merge(a, value)}
              end
            else
              {
                Utils.to_uid(ext_type, name),
                add_extension(value, ext_type, ext_uid)
              }
            end
          end)
        )
      end)
      |> merge_ext_types(ext_data)
    else
      acc
    end
  end

  defp merge_ext_types(acc, ext) do
    if acc[:types] != nil and ext[:types] != nil do
      update_in(acc, [:types, :attributes], fn types ->
        Utils.deep_merge(
          types,
          get_in(ext, [:types, :attributes])
        )
      end)
    else
      acc
    end
  end

  defp read_extension_dir(acc, home, ext, dir) do
    path = Path.join(ext[:path], dir)

    if File.dir?(path) do
      read_extension_files(acc, home, ext, path)
    else
      acc
    end
  end

  defp read_extension_files(acc, home, ext, path) do
    if File.dir?(path) do
      Logger.info("[#{ext[:name]}] read files: #{path}")

      case File.ls(path) do
        {:ok, files} ->
          files
          |> Stream.map(fn file -> Path.join(path, file) end)
          |> Enum.reduce(acc, fn file, map -> read_extension_files(map, home, ext, file) end)

        error ->
          Logger.warning("unable to access #{path} directory. Error: #{inspect(error)}")
          System.stop(0)
      end
    else
      if Path.extname(path) == @schema_file do
        Logger.debug("[#{ext[:name]}] read file: #{path}")

        data =
          read_json_file(path)
          |> resolve_extension_includes(home, ext)
          |> add_extension(ext[:name], ext[:uid])

        name = Utils.to_uid(ext[:name], data[:name] || Path.basename(data[:extends]))
        Map.put(acc, name, data)
      else
        acc
      end
    end
  end

  defp add_extension(map, type, uid) do
    map
    |> Map.put(:extension, type)
    |> Map.put(:extension_id, uid)
  end

  defp resolve_includes(data, home) do
    read_included_files(data, Map.get(data, :attributes), fn file ->
      resolve_file(home, file)
    end)
  end

  defp resolve_extension_includes(data, home, ext) do
    read_included_files(data, Map.get(data, :attributes), fn file ->
      resolve_file(home, ext, file)
    end)
  end

  defp read_included_files(data, nil, _resolver), do: data

  defp read_included_files(data, attributes, resolver) do
    case Map.get(attributes, @include) do
      nil ->
        data

      file when is_binary(file) ->
        include_files(resolver, file, data)

      files when is_list(files) ->
        Enum.reduce(files, data, fn file, acc -> include_files(resolver, file, acc) end)
    end
    |> include_enums(resolver)
  end

  defp include_files(resolver, file, data) do
    included = read_included_file(resolver, file)
    attributes = Utils.deep_merge(included[:attributes], Map.delete(data[:attributes], @include))
    Map.put(data, :attributes, attributes)
  end

  defp include_enums(class, resolver) do
    Map.update(class, :attributes, [], fn attributes -> merge_enums(resolver, attributes) end)
  end

  defp merge_enums(resolver, attributes) do
    Enum.into(
      attributes,
      Map.new(),
      fn {name, attribute} ->
        {name, merge_enum_file(resolver, attribute)}
      end
    )
  end

  defp merge_enum_file(_resolver, nil) do
    nil
  end

  defp merge_enum_file(resolver, attribute) do
    case Map.get(attribute, @include) do
      nil ->
        attribute

      file ->
        read_included_file(resolver, file) |> Utils.deep_merge(Map.delete(attribute, @include))
    end
  end

  defp read_included_file(resolver, file) do
    {ext, path} = resolver.(file)
    Logger.debug("[#{ext}] include file #{path}")

    case cache_get(path) do
      [] ->
        read_json_file(path) |> update_profile_attributes(ext, file) |> cache_put(path)

      [{_, cached}] ->
        cached
    end
  end

  defp update_profile_attributes(data, ext, file) do
    {name, data} =
      case data[:meta] do
        "profile" ->
          update_profile(data, ext)

        _ ->
          {nil, data}
      end

    data =
      case data[:annotations] do
        nil ->
          Map.update(data, :attributes, [], fn attributes ->
            add_profile(attributes, name)
          end)

        annotations ->
          Map.update(data, :attributes, [], fn attributes ->
            add_annotated_profile(attributes, name, annotations)
          end)
      end

    if data[:meta] == "profile" do
      put_profile(name, data, ext, file)
    end

    data
  end

  defp update_profile(profile, ext) do
    if ext == nil do
      {profile[:name], profile}
    else
      {Path.join([ext, profile[:name]]), Map.put(profile, :extension, ext)}
    end
  end

  defp put_profile(name, profile, ext, file) do
    profiles = get_profiles()

    case profiles[String.to_atom(name)] do
      nil ->
        Logger.info("[#{ext}] read profile '#{name}' from #{file}")
        Map.put(profiles, name, profile) |> cache_put(:profiles)

      _profile ->
        Logger.warning("[#{ext}] #{file} overwrites an existing profile #{name}")
    end
  end

  defp get_profiles() do
    case cache_get(:profiles) do
      [{_, cached}] -> cached
      [] -> %{}
    end
  end

  defp add_profile(attributes, nil) do
    attributes
  end

  defp add_profile(attributes, profile) do
    Enum.into(attributes, %{}, fn {name, attribute} ->
      {name, Map.put(attribute, :profile, profile)}
    end)
  end

  defp add_annotated_profile(attributes, nil, annotations) do
    Enum.into(attributes, %{}, fn {name, attribute} ->
      {name, Utils.deep_merge(annotations, attribute)}
    end)
  end

  defp add_annotated_profile(attributes, profile, annotations) do
    Enum.into(attributes, %{}, fn {name, attribute} ->
      {name, Utils.deep_merge(annotations, Map.put(attribute, :profile, profile))}
    end)
  end

  # Extensions
  @spec read_extensions(any, binary | maybe_improper_list) :: any
  def read_extensions(home, path) when is_binary(path) do
    find_extensions(home, path, [])
  end

  def read_extensions(home, list) when is_list(list) do
    Enum.reduce(list, [], fn path, acc ->
      find_extensions(home, String.trim(path), acc)
    end)
    |> Enum.uniq_by(fn ext -> ext[:path] end)
  end

  defp find_extensions(home, path, list) do
    path =
      if File.dir?(path) do
        path
      else
        Path.join(home, path) |> Path.absname()
      end

    if File.dir?(path) do
      find_extensions(path, list)
    else
      Logger.warning("invalid extensions path: #{path}")
      list
    end
  end

  defp find_extensions(path, list) do
    if File.dir?(path) do
      case read_extension(path) do
        false ->
          case File.ls(path) do
            {:ok, files} ->
              files
              |> Enum.map(fn file -> Path.join(path, file) end)
              |> Enum.reduce(list, fn file, acc -> find_extensions(file, acc) end)

            error ->
              error("unable to access #{path} directory. Error: #{inspect(error)}")
          end

        data ->
          [Map.put(data, :path, path) | list]
      end
    else
      list
    end
  end

  defp read_extension(path) do
    file = Path.join(path, @extension_file)

    if File.regular?(file) do
      read_json_file(file)
    else
      false
    end
  end

  defp error(message) do
    Logger.error(message)
    System.stop(1)
  end

  defp resolve_file(home, file) do
    path = Path.join(home, file)

    if File.regular?(path) do
      {nil, path}
    else
      error("file #{path} not found in #{home}")
    end
  end

  defp resolve_file(home, ext, file) do
    path = Path.join(ext[:path], file)
    ext_name = ext[:name]

    if File.regular?(path) do
      {ext_name, path}
    else
      path = Path.join(home, file)

      if File.regular?(path) do
        {ext_name, path}
      else
        error("file #{path} not found in [#{ext[:path]}, #{home}]")
      end
    end
  end

  # ETS cache for the included json files
  defp init_cache() do
    name = __MODULE__

    case :ets.info(name) do
      :undefined ->
        :ets.new(name, [:set, :protected, :named_table])

      _ ->
        error("ETS table with name #{name} already exists.")
    end
  end

  defp cache_put(data, path) do
    :ets.insert(__MODULE__, {path, data})
    data
  end

  defp cache_get(path) do
    :ets.lookup(__MODULE__, path)
  end

  defp delete() do
    :ets.delete_all_objects(__MODULE__)
  end
end
