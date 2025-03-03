# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.Generator do
  @moduledoc """
  Random data generator using the event schema.
  """

  use Agent

  alias __MODULE__
  alias Schema.Types
  alias Schema.Utils

  require Logger

  defstruct ~w[countries tactics names words files]a

  @spec start :: {:error, any} | {:ok, pid}
  def start(), do: Agent.start(fn -> init() end, name: __MODULE__)

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_), do: Agent.start_link(fn -> init() end, name: __MODULE__)

  @data_dir "priv/data"

  @countries_file "country-and-continent-codes-list.json"

  # MITRE ATT&CK files
  @tactics_file "enterprise-tactics.json"

  @files_file "files.txt"
  @names_file "names.txt"
  @words_file "words.txt"

  @requirement 100
  @recommended 90
  @optional 20
  @max_array_size 3
  @other 99

  def init() do
    dir = Application.app_dir(:schema_server, @data_dir)

    countries = read_countries(Path.join(dir, @countries_file))

    tactics = read_json_file(Path.join(dir, @tactics_file))

    files = read_file_types(Path.join(dir, @files_file))
    names = read_data_file(Path.join(dir, @names_file))
    words = read_data_file(Path.join(dir, @words_file))

    %Generator{
      countries: countries,
      tactics: tactics,
      files: files,
      names: names,
      words: words
    }
  end

  @spec generate_sample_event(Schema.Cache.class_t(), Schema.Repo.profiles_t() | nil) :: map()
  def generate_sample_event(class, nil) do
    Logger.debug("generate sample event: #{inspect(class[:name])}")

    generate_sample_event(class) |> remove_profiles()
  end

  def generate_sample_event(class, profiles) do
    Logger.debug(fn ->
      "generate sample event: #{class[:name]}, profiles: #{MapSet.to_list(profiles) |> Enum.join(", ")})"
    end)

    Process.put(:profiles, profiles)
    generate_event(class, profiles, MapSet.size(profiles))
  end

  @spec generate_sample_event(Schema.Cache.object_t(), Schema.Repo.profiles_t() | nil) :: map()
  def generate_sample_object(type, nil) do
    Logger.debug("generate sample object: #{type[:name]})")

    generate_sample_object(type)
  end

  def generate_sample_object(type, profiles) do
    Logger.debug(fn ->
      "generate sample object: #{type[:name]}, profiles: #{MapSet.to_list(profiles) |> Enum.join(", ")})"
    end)

    Process.put(:profiles, profiles)
    generate_sample_object(type, profiles, MapSet.size(profiles))
  end

  defp generate_event(class, _profiles, 0) do
    Map.update!(class, :attributes, fn attributes ->
      Utils.remove_profiles(attributes)
    end)
    |> generate_sample_event()
  end

  defp generate_event(class, profiles, size) do
    Map.update!(class, :attributes, fn attributes ->
      Utils.apply_profiles(attributes, profiles, size)
    end)
    |> generate_sample_event()
    |> add_profiles(MapSet.to_list(profiles))
  end

  defp add_profiles(data, profiles) do
    put_in(data, [:metadata, :profiles], profiles)
  end

  defp remove_profiles(data) do
    {_, map} = pop_in(data, [:metadata, :profiles])
    map
  end

  defp generate_sample_event(class) do
    data = generate_sample(class)

    case data[:activity_id] do
      nil ->
        data

      activity_id ->
        uid =
          if activity_id >= 0 do
            Types.type_uid(data[:class_uid], activity_id)
          else
            @other
          end

        Map.put(data, :type_uid, uid)
        |> put_type_name(uid, class)
        |> Map.delete(:raw_data)
        |> Map.delete(:unmapped)
    end
  end

  defp generate_sample_object(type, _profiles, 0) do
    Map.update!(type, :attributes, fn attributes ->
      Utils.remove_profiles(attributes)
    end)
    |> generate_sample_object()
  end

  defp generate_sample_object(type, profiles, size) do
    Map.update!(type, :attributes, fn attributes ->
      Utils.apply_profiles(attributes, profiles, size)
    end)
    |> generate_sample_object()
  end

  defp generate_sample_object(type) do
    Logger.debug("generate #{type[:name]} (#{type[:caption]})")

    case type[:name] do
      "fingerprint" -> fingerprint(type)
      "location" -> location()
      "attack" -> attack()
      "file" -> generate_sample(type) |> update_file_path()
      _type -> generate_sample(type)
    end
  end

  @doc """
  Generate new event class uid values for a given category.
  """
  @spec update_classes(binary(), integer()) :: any()
  def update_classes(path, uid) when is_binary(path) and is_integer(uid) do
    if File.dir?(path) do
      read_classes(nil, path, [])
      |> Enum.sort()
      |> Enum.reduce(uid, fn {_, file}, next -> update_classes(file, next) end)
    else
      update_class_uid(path, uid)
    end
  end

  @doc """
  Generate new domain uid values for a given main domain.
  """
  @spec update_domains(binary(), integer()) :: any()
  def update_domains(path, uid) when is_binary(path) and is_integer(uid) do
    if File.dir?(path) do
      read_domains(nil, path, [])
      |> Enum.sort()
      |> Enum.reduce(uid, fn {_, file}, next -> update_domains(file, next) end)
    else
      update_domain_uid(path, uid)
    end
  end

  @doc """
  Generate new feature uid values for a given main feature.
  """
  @spec update_features(binary(), integer()) :: any()
  def update_features(path, uid) when is_binary(path) and is_integer(uid) do
    if File.dir?(path) do
      read_features(nil, path, [])
      |> Enum.sort()
      |> Enum.reduce(uid, fn {_, file}, next -> update_features(file, next) end)
    else
      update_feature_uid(path, uid)
    end
  end

  defp put_type_name(data, uid, class) do
    case get_in(class, [:attributes, :type_uid, :enum]) do
      nil ->
        data

      enum ->
        key = Integer.to_string(uid) |> String.to_atom()
        name = get_in(enum, [key, :caption]) || "Unknown"
        Map.put(data, :type_name, name)
    end
  end

  defp generate_sample(type) do
    Enum.reduce(type[:attributes], Map.new(), fn {name, field} = attribute, map ->
      if field[:is_array] == true do
        generate_array(field[:requirement], name, attribute, map)
      else
        case field[:type] do
          "object_t" ->
            generate_object(field[:requirement], name, attribute, map)

          nil ->
            Logger.warning("Invalid type name: #{name}")
            map

          _other ->
            generate(attribute, map)
        end
      end
    end)
  end

  defp generate({name, field}, map) do
    generate_field(field[:requirement], name, field, map)
  end

  #  Generate all required fields
  defp generate_field("required", name, field, map) do
    generate_field(name, field, map)
  end

  #  Generate % of the recommended fields
  defp generate_field("recommended", name, field, map) do
    if random(@requirement) < @recommended do
      generate_field(name, field, map)
    else
      map
    end
  end

  #  Generate % of the optional fields
  defp generate_field(_requirement, name, field, map) do
    if random(@requirement) < @optional do
      generate_field(name, field, map)
    else
      map
    end
  end

  defp generate_field(name, %{type: "integer_t"} = field, map) do
    case field[:enum] do
      nil ->
        Map.put(map, name, random(100))

      enum ->
        generate_enum_data(name, field[:sibling], enum, map)
    end
  end

  defp generate_field(name, %{type: "string_t"} = field, map) do
    case field[:enum] do
      nil ->
        Map.put_new(map, name, generate_data(name, field[:type], field))

      enum ->
        Map.put(map, name, random_enum_value(enum))
    end
  end

  defp generate_field(name, field, map) do
    Map.put_new(map, name, generate_data(name, field[:type], field))
  end

  defp generate_enum_data(key, nil, enum, map) do
    id = random_enum_int_value(enum)
    Map.put(map, key, id)
  end

  defp generate_enum_data(key, name, enum, map) do
    name = String.to_atom(name)
    id = random_enum_int_value(enum)

    if id == @other do
      Map.put(map, name, word())
    else
      Map.put(map, name, enum_name(Integer.to_string(id), enum))
    end
    |> Map.put(key, id)
  end

  defp enum_name(name, enum) do
    key = String.to_atom(name)

    case enum[key] do
      nil -> word()
      val -> val[:caption]
    end
  end

  defp generate_array("required", name, attribute, map) do
    Map.put(map, name, generate_array(attribute))
  end

  defp generate_array("recommended", name, attribute, map) do
    if random(@requirement) < @recommended do
      Map.put(map, name, generate_array(attribute))
    else
      map
    end
  end

  defp generate_array(_, name, attribute, map) do
    if random(@requirement) < @optional do
      Map.put(map, name, generate_array(attribute))
    else
      map
    end
  end

  defp generate_array({:coordinates, _field}) do
    [random_float(360, 180), random_float(180, 90)]
  end

  defp generate_array({:loaded_modules, _field}) do
    Enum.map(1..random(@max_array_size), fn _ -> file_name(4) end)
  end

  defp generate_array({:fingerprints, type}) do
    1..random(@max_array_size)
    |> Enum.map(fn _ -> fingerprint(find_object(type)) end)
    |> Enum.uniq_by(fn map -> Map.get(map, :algorithm_id) end)
  end

  defp generate_array({:image_labels, _field}) do
    words(5)
  end

  defp generate_array({name, field} = attribute) do
    n = random(@max_array_size)

    case field[:type] do
      "object_t" ->
        generate_objects(n, attribute)

      type ->
        Enum.map(1..n, fn _ -> generate_data(name, type, field) end)
    end
  end

  defp generate_object("required", name, attribute, map) do
    Map.put(map, name, generate_object(attribute))
  end

  defp generate_object("recommended", name, attribute, map) do
    if random(@requirement) < @recommended do
      Map.put(map, name, generate_object(attribute))
    else
      map
    end
  end

  defp generate_object(_, name, attribute, map) do
    if random(@requirement) < @optional do
      Map.put(map, name, generate_object(attribute))
    else
      map
    end
  end

  defp generate_object({:file_result, field}) do
    generate_file_object(field)
  end

  defp generate_object({:file, field}) do
    generate_file_object(field)
  end

  defp generate_object({_name, field}) do
    find_object(field) |> generate_sample_object(Process.get(:profiles))
  end

  defp find_object(field) do
    Schema.object(field[:object_type])
  end

  defp generate_file_object(field) do
    field[:object_type]
    |> String.to_atom()
    |> Schema.object()
    |> generate_sample_object(Process.get(:profiles))
    |> update_file_path()
  end

  defp update_file_path(file) do
    filename = file_name(0)

    case Map.get(file, :path) do
      nil ->
        file
        |> Map.put(:name, filename)
        |> Map.delete(:parent_folder)

      path ->
        pathname = Path.join(path, filename)

        file
        |> Map.put(:name, filename)
        |> Map.put(:path, pathname)
        |> Map.put(:parent_folder, path)
    end
  end

  defp generate_objects(n, {:attacks, _field}) do
    Enum.map(1..n, fn _ -> attack() end)
  end

  defp generate_objects(n, {_name, field}) do
    object =
      field[:object_type]
      |> String.to_atom()
      |> Schema.object()

    Enum.map(1..n, fn _ -> generate_sample_object(object, Process.get(:profiles)) end)
  end

  defp generate_data(:ref_time, _type, _field),
    do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp generate_data(:version, _type, _field), do: Schema.version()
  defp generate_data(:lang, _type, _field), do: "en"
  defp generate_data(:uuid, _type, _field), do: uuid()
  defp generate_data(:uid, _type, _field), do: uuid()
  defp generate_data(:creator, _type, _field), do: full_name(2)
  defp generate_data(:accessor, _type, _field), do: full_name(2)
  defp generate_data(:modifier, _type, _field), do: full_name(2)
  defp generate_data(:full_name, _type, _field), do: full_name(2)
  defp generate_data(:shell, _type, _field), do: shell()
  defp generate_data(:timezone_offset, _type, _field), do: timezone()
  defp generate_data(:home_dir, _type, _field), do: root_dir(random(3))
  defp generate_data(:parent_folder, _type, _field), do: root_dir(random(3))
  defp generate_data(:country, _type, _field), do: country()[:country_name]
  defp generate_data(:company_name, _type, _field), do: full_name(2)
  defp generate_data(:owner, _type, _field), do: full_name(2)
  defp generate_data(:labels, _type, _field), do: word()
  defp generate_data(:facility, _type, _field), do: facility()
  defp generate_data(:mime_type, _type, _field), do: path_name(2)

  defp generate_data(key, "string_t", _field) do
    name = Atom.to_string(key)

    if String.ends_with?(name, "_uid") do
      uuid()
    else
      if String.ends_with?(name, "_ver") do
        version()
      else
        if String.ends_with?(name, "_code") do
          word()
        else
          sentence(3)
        end
      end
    end
  end

  defp generate_data(_name, "integer_t", field) do
    case field[:enum] do
      nil ->
        random(100)

      enum ->
        random_enum_int_value(enum)
    end
  end

  defp generate_data(_name, "timestamp_t", _field),
    do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  defp generate_data(_name, "datetime_t", _field),
    do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp generate_data(_name, "hostname_t", _field), do: domain()
  defp generate_data(_name, "ip_t", _field), do: ipv4()
  defp generate_data(_name, "subnet_t", _field), do: subnet()
  defp generate_data(_name, "mac_t", _field), do: mac()
  defp generate_data(_name, "email_t", _field), do: email()
  defp generate_data(_name, "port_t", _field), do: random(65_536)
  defp generate_data(_name, "long_t", _field), do: random(65_536 * 65_536)
  defp generate_data(_name, "boolean_t", _field), do: random_boolean()
  defp generate_data(_name, "float_t", _field), do: random_float(100, 100)
  defp generate_data(_name, "file_name_t", _field), do: file_name(0)
  defp generate_data(_name, "path_t", _field), do: root_dir(5)

  defp generate_data(:type, _type, _field), do: word()
  defp generate_data(:name, _type, _field), do: String.capitalize(word())
  defp generate_data(_name, _, _), do: word()

  def name() do
    Agent.get(__MODULE__, fn %Generator{names: {len, names}} -> random_word(len, names) end)
  end

  def names(n) do
    Agent.get(__MODULE__, fn %Generator{names: {len, names}} ->
      Enum.map(1..n, fn _ -> random_word(len, names) end)
    end)
  end

  def full_name(len) do
    names(len) |> Enum.join(" ")
  end

  def word() do
    Agent.get(__MODULE__, fn %Generator{words: {len, words}} -> random_word(len, words) end)
  end

  def words(n) do
    Agent.get(__MODULE__, fn %Generator{words: {len, words}} ->
      Enum.map(1..n, fn _ -> random_word(len, words) end)
    end)
  end

  def sentence(len) do
    words(len) |> Enum.join(" ")
  end

  def version() do
    n = random(3) + 1
    Enum.map_join(1..n, ".", fn _ -> random(5) end)
  end

  def path_name(len) do
    words(len) |> Path.join()
  end

  def root_dir(len) do
    "/" <> path_name(len)
  end

  def file_name(0) do
    word() <> file_ext()
  end

  def file_name(len) do
    root_dir(len + 1) <> file_ext()
  end

  def win_file(len) do
    "\\" <> (words(len) |> Enum.join("\\"))
  end

  def file_ext() do
    [ext, _] =
      Agent.get(__MODULE__, fn %Generator{files: {len, words}} ->
        random_word(len, words)
      end)

    ext
  end

  def blake2() do
    :crypto.hash(:blake2s, Schema.Generator.word()) |> Base.encode16()
  end

  def blake2b() do
    :crypto.hash(:blake2b, Schema.Generator.word()) |> Base.encode16()
  end

  def sha512() do
    :crypto.hash(:sha512, Schema.Generator.word()) |> Base.encode16()
  end

  def sha256() do
    :crypto.hash(:sha256, Schema.Generator.word()) |> Base.encode16()
  end

  def sha1() do
    :crypto.hash(:sha, Schema.Generator.word()) |> Base.encode16()
  end

  def md5() do
    :crypto.hash(:md5, Schema.Generator.word()) |> Base.encode16()
  end

  def shell() do
    Enum.random(["bash", "zsh", "fish", "sh"])
  end

  # 00:25:96:FF:FE:12:34:56
  def mac() do
    Enum.map_join(1..8, ":", fn _n -> random(256) |> Integer.to_string(16) end)
  end

  def ipv4() do
    Enum.map_join(1..4, ".", fn _n -> random(256) end)
  end

  # 2001:0000:3238:DFE1:0063:0000:0000:FEFB
  def ipv6() do
    Enum.map_join(1..8, ":", fn _n ->
      random(65_536)
      |> Integer.to_string(16)
      |> String.pad_leading(4, "0")
    end)
  end

  # 192.168.10/8
  def subnet() do
    n = random(3)

    ip =
      Enum.map_join(0..n, ".", fn _n -> random(256) end) <>
        "." <>
        Enum.map_join(1..(3 - n), ".", fn _n -> 0 end)

    case n do
      0 -> ip <> "/8"
      1 -> ip <> "/16"
      2 -> ip <> "/24"
    end
  end

  def email() do
    [name(), "@", domain()] |> Enum.join()
  end

  def domain() do
    [word(), extension()] |> Enum.join(".")
  end

  def uuid() do
    UUID.uuid1()
  end

  def timezone() do
    (12 - random(24)) * 60
  end

  def random(n), do: :rand.uniform(n) - 1

  def random_boolean(), do: random(2) == 1

  def country() do
    Agent.get(__MODULE__, fn %Generator{countries: {len, names}} -> random_word(len, names) end)
  end

  def tactics() do
    Agent.get(__MODULE__, fn %Generator{tactics: {_len, tactics}} ->
      Enum.map(1..(random(3) + 1), fn _ ->
        {uid, name} = Enum.random(tactics)
        %{:uid => uid, :name => name}
      end)
    end)
  end

  def attack() do
    Map.new()
    |> Map.put(:tactics, tactics())
    |> Map.put(:version, "12.1")
  end

  def location() do
    country = country()

    %{
      coordinates: coordinates(),
      continent: country.continent_name,
      country: country.two_letter_country_code,
      city: sentence(2) |> String.capitalize(),
      desc: country.country_name
    }
  end

  def coordinates() do
    [random_float(360, 180), random_float(180, 90)]
  end

  def random_float(n, r), do: Float.ceil(r - :rand.uniform_real() * n, 4)

  def fingerprint(type) do
    algorithm_id = get_in(type, [:attributes, :algorithm_id])

    fingerprint =
      generate_enum_data(
        :algorithm_id,
        algorithm_id[:sibling],
        algorithm_id[:enum],
        Map.new()
      )

    algorithm = fingerprint[:algorithm_id]

    value =
      case algorithm do
        @other ->
          blake2()

        1 ->
          md5()

        2 ->
          sha1()

        3 ->
          sha256()

        _ ->
          blake2b()
      end

    fingerprint = Map.put(fingerprint, :value, value)

    if algorithm == @other do
      Map.put(fingerprint, :algorithm, "magic")
    else
      fingerprint
    end
  end

  defp random_enum_int_value(enum) do
    random_enum_value(enum) |> String.to_integer()
  end

  defp random_enum_value(enum) do
    {name, _} = Enum.random(enum)
    Atom.to_string(name)
  end

  defp random_word(len, words) do
    :array.get(random(len), words)
  end

  def extension() do
    Enum.random([
      "aero",
      "arpa",
      "biz",
      "cat",
      "com",
      "coop",
      "edu",
      "firm",
      "gov",
      "info",
      "int",
      "jobs",
      "mil",
      "mobi",
      "museum",
      "name",
      "nato",
      "net",
      "org",
      "pro",
      "store",
      "travel",
      "web"
    ])
  end

  def facility() do
    Enum.random([
      "kern",
      "user",
      "mail",
      "daemon",
      "auth",
      "syslog",
      "lpr",
      "news",
      "uucp",
      "cron",
      "authpriv",
      "ftp",
      "local0",
      "local7"
    ])
  end

  defp read_data_file(filename) do
    list = File.stream!(filename) |> Stream.map(&String.trim_trailing/1) |> Enum.to_list()

    {length(list), :array.from_list(list)}
  end

  defp read_file_types(filename) do
    list =
      File.stream!(filename)
      |> Stream.map(&String.trim_trailing/1)
      |> Stream.map(fn s -> String.split(s, "\t") end)
      |> Stream.map(fn [ext, desc] -> [String.downcase(ext), desc] end)
      |> Enum.to_list()

    {length(list), :array.from_list(list)}
  end

  defp read_countries(filename) do
    list = File.read!(filename) |> Jason.decode!(keys: :atoms)

    {length(list), :array.from_list(list)}
  end

  defp read_json_file(filename) do
    map = File.read!(filename) |> Jason.decode!()

    {map_size(map), map}
  end

  def read_classes(path) do
    if File.dir?(path) do
      read_classes(nil, path, []) |> Enum.sort()
    else
      []
    end
  end

  defp read_classes(name, path, list) do
    if File.dir?(path) do
      case File.ls(path) do
        {:ok, files} ->
          Enum.reduce(files, list, fn file, acc ->
            read_classes(file, Path.join(path, file), acc)
          end)

        error ->
          exit(error)
      end
    else
      if Path.extname(name) == ".json" do
        [{name, path} | list]
      else
        list
      end
    end
  end

  defp update_class_uid(file, uid) do
    data = File.read!(file) |> Jason.decode!()

    case Map.get(data, "uid") do
      nil ->
        uid

      _uid ->
        Map.put(data, "uid", uid) |> write_json(file)
        uid + 1
    end
  end

  def read_domains(path) do
    if File.dir?(path) do
      read_domains(nil, path, []) |> Enum.sort()
    else
      []
    end
  end

  defp read_domains(name, path, list) do
    if File.dir?(path) do
      case File.ls(path) do
        {:ok, files} ->
          Enum.reduce(files, list, fn file, acc ->
            read_domains(file, Path.join(path, file), acc)
          end)

        error ->
          exit(error)
      end
    else
      if Path.extname(name) == ".json" do
        [{name, path} | list]
      else
        list
      end
    end
  end

  defp update_domain_uid(file, uid) do
    data = File.read!(file) |> Jason.decode!()

    case Map.get(data, "uid") do
      nil ->
        uid

      _uid ->
        Map.put(data, "uid", uid) |> write_json(file)
        uid + 1
    end
  end

  def read_features(path) do
    if File.dir?(path) do
      read_features(nil, path, []) |> Enum.sort()
    else
      []
    end
  end

  defp read_features(name, path, list) do
    if File.dir?(path) do
      case File.ls(path) do
        {:ok, files} ->
          Enum.reduce(files, list, fn file, acc ->
            read_features(file, Path.join(path, file), acc)
          end)

        error ->
          exit(error)
      end
    else
      if Path.extname(name) == ".json" do
        [{name, path} | list]
      else
        list
      end
    end
  end

  defp update_feature_uid(file, uid) do
    data = File.read!(file) |> Jason.decode!()

    case Map.get(data, "uid") do
      nil ->
        uid

      _uid ->
        Map.put(data, "uid", uid) |> write_json(file)
        uid + 1
    end
  end

  defp write_json(data, filename) do
    # if File.exists?(filename) do
    #   File.rename!(filename, filename <> ".bak")
    # end

    File.write!(filename, Jason.encode!(data, pretty: true))
  end
end
