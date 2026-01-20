# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Validator do
  @moduledoc """
  OASF validator.
  """

  # Implementation note:
  # The validate_* and add_* functions (other than the top level validate/1 and validate_bundle/1
  # functions) take a response and return one, possibly updated.
  # The overall flow is to examine the class/object or list of classes/objects, and return a validation response.

  require Logger

  @spec validate(map(), list(), atom()) :: map()
  def validate(data, options, type) when is_map(data) do
    validate_input(data, options, Schema.dictionary(), type)
  end

  @spec validate_bundle(map(), list(), atom()) :: map()
  def validate_bundle(bundle, options, type) when is_map(bundle) do
    bundle_structure = get_bundle_structure()

    # First validate the bundle itself
    response =
      Enum.reduce(
        bundle_structure,
        %{},
        fn attribute_tuple, response ->
          validate_bundle_attribute(response, bundle, attribute_tuple)
        end
      )

    # Check that there are no extra keys in the bundle
    response =
      Enum.reduce(
        bundle,
        response,
        fn {key, _}, response ->
          if Map.has_key?(bundle_structure, key) do
            response
          else
            add_error(
              response,
              "attribute_unknown",
              "Unknown attribute \"#{key}\" in input bundle.",
              %{attribute_path: key, attribute: key}
            )
          end
        end
      )

    # TODO: validate the bundle times and count against inputs

    # Next validate the inputs in the bundle
    response =
      validate_bundle_inputs(
        response,
        bundle,
        options,
        Schema.dictionary(),
        type
      )

    finalize_response(response)
  end

  # Returns structure of an input bundle.
  # See "Bundling" here: https://github.com/OASF/examples/blob/main/encodings/json/README.md
  @spec get_bundle_structure() :: map()
  defp get_bundle_structure() do
    %{
      "inputs" => {:required, "array", &is_list/1},
      "count" => {:optional, "integer_t", &is_integer_t/1}
    }
  end

  @spec validate_bundle_attribute(map(), map(), tuple()) :: map()
  defp validate_bundle_attribute(
         response,
         bundle,
         {attribute_name, {requirement, type_name, is_type_fn}}
       ) do
    if Map.has_key?(bundle, attribute_name) do
      value = bundle[attribute_name]

      if is_type_fn.(value) do
        response
      else
        add_error_wrong_type(response, attribute_name, attribute_name, value, type_name)
      end
    else
      if requirement == :required do
        add_error_required_attribute_missing(response, attribute_name, attribute_name)
      else
        response
      end
    end
  end

  @spec validate_bundle_inputs(map(), map(), list(), map(), atom()) :: map()
  defp validate_bundle_inputs(response, bundle, options, dictionary, class_type) do
    inputs = bundle["inputs"]

    if is_list(inputs) do
      Map.put(
        response,
        :input_validations,
        Enum.map(
          inputs,
          fn input ->
            if is_map(input) do
              validate_input(input, options, dictionary, class_type)
            else
              {type, type_extra} = type_of(input)

              %{
                error: "input has wrong type; expected object, got #{type}#{type_extra}.",
                type: type,
                expected_type: "object"
              }
            end
          end
        )
      )
    else
      response
    end
  end

  @spec validate_input(map(), list(), map(), atom()) :: map()
  defp validate_input(input, options, dictionary, type) do
    response = new_response(input)

    {response, class} =
      case type do
        :skill ->
          validate_class_id_or_name(response, input, "", &Schema.find_skill/1, &Schema.skill/1)

        :domain ->
          validate_class_id_or_name(response, input, "", &Schema.find_domain/1, &Schema.domain/1)

        :module ->
          validate_class_id_or_name(response, input, "", &Schema.find_module/1, &Schema.module/1)

        :object ->
          validate_object_name_and_return_object(response, options, "")

        _ ->
          # Unknown type; return error
          add_error(
            response,
            "input_type_unknown",
            "Unknown input type \"#{type}\".",
            %{attribute_path: "type", attribute: "type", value: type}
          )
      end

    response =
      if class do
        {response, profiles} = validate_and_return_profiles(response, input)

        validate_input_against_class(
          response,
          input,
          class,
          profiles,
          options,
          dictionary,
          ""
        )
      else
        # Can't continue if we can't find the class
        response
      end

    finalize_response(response)
  end

  defp validate_class_id_or_name(response, input, attribute_path, find_by_id, find_by_name) do
    # Validate ID if present
    {id_response, class_by_id} =
      if Map.has_key?(input, "id") do
        validate_class_id_and_return_class(find_by_id, response, input, attribute_path)
      else
        {response, nil}
      end

    # Validate name if present (using updated response to accumulate errors)
    {final_response, class_by_name} =
      if Map.has_key?(input, "name") do
        validate_class_name_and_return_class(find_by_name, id_response, input, attribute_path)
      else
        {id_response, nil}
      end

    # Handle cases
    cond do
      # Both missing
      !Map.has_key?(input, "id") && !Map.has_key?(input, "name") ->
        {add_error_required_attribute_missing(final_response, attribute_path, "id or name"), nil}

      # ID present but invalid OR name present but invalid
      (Map.has_key?(input, "id") && is_nil(class_by_id)) ||
          (Map.has_key?(input, "name") && is_nil(class_by_name)) ->
        {final_response, nil}

      # Only one valid identifier
      class_by_id && is_nil(class_by_name) ->
        {final_response, class_by_id}

      class_by_name && is_nil(class_by_id) ->
        {final_response, class_by_name}

      # Both valid - check consistency
      true ->
        if class_by_id.uid == class_by_name.uid do
          {final_response, class_by_id}
        else
          error_msg =
            "ID and name refer to different classes. " <>
              "ID #{input["id"]} points to class #{class_by_id.name}, " <>
              "name '#{input["name"]}' points to class #{class_by_name.name}."

          {add_error(
             final_response,
             "id_name_mismatch",
             error_msg,
             %{attribute_path: attribute_path, attribute: "id or name"}
           ), nil}
        end
    end
  end

  @spec validate_class_id_and_return_class((any -> any), map(), map(), String.t()) ::
          {map(), nil | map()}
  defp validate_class_id_and_return_class(
         find_class_function,
         response,
         input,
         attribute_path
       ) do
    if Map.has_key?(input, "id") do
      class_uid = input["id"]

      cond do
        is_integer_t(class_uid) ->
          case find_class_function.(class_uid) do
            nil ->
              {
                add_error(
                  response,
                  "id_unknown",
                  "Unknown \"id\" value; no class is defined for #{class_uid}.",
                  %{attribute_path: attribute_path, attribute: "id", value: class_uid}
                ),
                nil
              }

            class ->
              {response, class}
          end

        true ->
          {
            # We need to add error here; no further validation will occur (nil returned for class).
            add_error_wrong_type(response, attribute_path, "id", class_uid, "integer_t"),
            nil
          }
      end
    else
      # We need to add error here; no further validation will occur (nil returned for class).
      {add_error_required_attribute_missing(response, attribute_path, "id"), nil}
    end
  end

  @spec validate_class_name_and_return_class((any -> any), map(), map(), String.t()) ::
          {map(), nil | map()}
  defp validate_class_name_and_return_class(
         find_class_function,
         response,
         input,
         attribute_path
       ) do
    if Map.has_key?(input, "name") do
      class_name = Schema.Utils.descope(input["name"])

      cond do
        is_bitstring(class_name) ->
          case find_class_function.(class_name) do
            nil ->
              {
                add_error(
                  response,
                  "name_unknown",
                  "Unknown \"name\" value; no class is defined for #{class_name}.",
                  %{attribute_path: attribute_path, attribute: "name", value: class_name}
                ),
                nil
              }

            class ->
              {response, class}
          end

        true ->
          {
            # We need to add error here; no further validation will occur (nil returned for class).
            add_error_wrong_type(response, attribute_path, "name", class_name, "string_t"),
            nil
          }
      end
    else
      # We need to add error here; no further validation will occur (nil returned for class).
      {add_error_required_attribute_missing(response, attribute_path, "name"), nil}
    end
  end

  @spec validate_object_name_and_return_object(map(), list(), String.t()) :: {map(), nil | map()}
  defp validate_object_name_and_return_object(response, options, attribute_path) do
    if Keyword.has_key?(options, :name) do
      object_name = Keyword.get(options, :name)

      cond do
        is_bitstring(object_name) ->
          case Schema.object(object_name) do
            nil ->
              {
                add_error(
                  response,
                  "name_unknown",
                  "Unknown \"name\" value; no object is defined for #{object_name}.",
                  %{attribute_path: attribute_path, attribute: "name", value: object_name}
                ),
                nil
              }

            object ->
              {response, object}
          end

        true ->
          {
            # We need to add error here; no further validation will occur (nil returned for class).
            add_error_wrong_type(response, "name", "name", object_name, "string_t"),
            nil
          }
      end
    else
      # We need to add error here; no further validation will occur (nil returned for class).
      {add_error_required_attribute_missing(response, "object_name", "object_name"), nil}
    end
  end

  @spec validate_and_return_profiles(map(), map()) :: {map(), list(String.t())}
  defp validate_and_return_profiles(response, input) do
    metadata = input["metadata"]

    if is_map(metadata) do
      profiles = metadata["profiles"]

      cond do
        is_list(profiles) ->
          # Ensure each profile is actually defined
          schema_profiles = MapSet.new(Map.keys(Schema.profiles()))

          {response, _} =
            Enum.reduce(
              profiles,
              {response, 0},
              fn profile, {response, index} ->
                response =
                  if is_binary(profile) and not MapSet.member?(schema_profiles, profile) do
                    attribute_path = make_attribute_path_array_element("metadata.profile", index)

                    add_error(
                      response,
                      "profile_unknown",
                      "Unknown profile at \"#{attribute_path}\";" <>
                        " no profile is defined for \"#{profile}\".",
                      %{attribute_path: attribute_path, attribute: "profiles", value: profile}
                    )
                  else
                    # Either profile is wrong type (which will be caught later)
                    # or this is a known profile
                    response
                  end

                {response, index + 1}
              end
            )

          {response, profiles}

        profiles == nil ->
          # profiles are missing or null, so return nil
          {response, nil}

        true ->
          # profiles are the wrong type, this will be caught later, so for now just return nil
          {response, nil}
      end
    else
      # metadata is missing or not a map (this will become an error), so return nil
      {response, nil}
    end
  end

  # This is similar to Schema.Utils.apply_profiles however this gives a result appropriate for
  # validation rather than for display in the web UI. Specifically, the Schema.Utils variation
  # returns _all_ attributes when the profiles parameter is nil, whereas for an input we want to
  # _always_ filter profile-specific attributes.
  @spec filter_with_profiles(Enum.t(), nil | list()) :: list()
  def filter_with_profiles(attributes, nil) do
    filter_with_profiles(attributes, [])
  end

  def filter_with_profiles(attributes, profiles) when is_list(profiles) do
    profile_set = MapSet.new(profiles)

    Enum.filter(attributes, fn {_k, v} ->
      case v[:profile] do
        nil -> true
        profile -> MapSet.member?(profile_set, profile)
      end
    end)
  end

  @spec validate_input_against_class(
          map(),
          map(),
          map(),
          list(String.t()),
          list(),
          map(),
          nil | String.t()
        ) ::
          map()
  defp validate_input_against_class(
         response,
         input,
         class,
         profiles,
         options,
         dictionary,
         parent_attribute_path
       ) do
    response
    |> validate_class_deprecated(class)
    |> validate_attributes(
      input,
      parent_attribute_path,
      class,
      profiles,
      options,
      dictionary,
      class[:is_enum] || false
    )
    |> validate_version(input)
    |> validate_constraints(input, class, parent_attribute_path)
  end

  @spec validate_class_deprecated(map(), map()) :: map()
  defp validate_class_deprecated(response, class) do
    if Map.has_key?(class, :"@deprecated") do
      add_warning_class_deprecated(response, class)
    else
      response
    end
  end

  @spec validate_version(map(), map()) :: map()
  defp validate_version(response, input) do
    if Map.has_key?(input, "schema_version") and is_binary(input["schema_version"]) do
      version = input["schema_version"]

      case Schema.Utils.parse_version(version) do
        {:error, error_message, _original} ->
          add_error(
            response,
            "version_invalid_format",
            "Schema version #{inspect(version)} at \"schema_version\" has invalid format:" <>
              " #{error_message}." <>
              " Version must be in semantic versioning format (see https://semver.org/).",
            %{
              attribute_path: "schema_version",
              attribute: "version",
              value: version,
              expected_regex: Schema.Utils.version_regex_source()
            }
          )

        parsed_version ->
          schema_version = Schema.version()

          case Schema.parsed_version() do
            {:error, error_message, _} ->
              # Comparing against invalid schema version
              add_error(
                response,
                "server_version_invalid_format",
                "Server's schema version #{inspect(schema_version)} has invalid format:" <>
                  " #{error_message}." <>
                  " Version must be in semantic versioning format (see https://semver.org/)." <>
                  " Please fix the schema version.",
                %{
                  value: schema_version,
                  expected_regex: Schema.Utils.version_regex_source()
                }
              )

            parsed_schema_version ->
              cond do
                parsed_version == parsed_schema_version ->
                  response

                Schema.Utils.version_sorter(parsed_version, parsed_schema_version) ->
                  # Schema version is before the current schema version (equal is covered above).
                  cond do
                    Schema.Utils.version_is_initial_development?(parsed_version) ->
                      # Initial development version -- versions a 0 major version like 0.1.0 -- do
                      # not have backwards compatible guarantees.
                      add_error(
                        response,
                        "version_incompatible_initial_development",
                        "Schema version \"#{version}\" at \"schema_version\" is an initial" <>
                          " development version and is incompatible with the current schema version" <>
                          " \"#{schema_version}\". Initial development versions do not have" <>
                          " compatibility guarantees (see https://semver.org/)." <>
                          " This can result in incorrect validation messages.",
                        %{
                          attribute_path: "schema_version",
                          attribute: "version",
                          value: version
                        }
                      )

                    Schema.Utils.version_is_prerelease?(parsed_version) ->
                      # Generally, earlier prerelease versions are incompatible with later versions.
                      add_error(
                        response,
                        "version_incompatible_prerelease",
                        "Schema version \"#{version}\" at \"schema_version\" is a prerelease" <>
                          " version and is incompatible with the current schema version" <>
                          " \"#{schema_version}\". Prerelease versions are generally" <>
                          " incompatible with released versions and future prerelease versions" <>
                          " (see https://semver.org/)." <>
                          " This can result in incorrect validation messages.",
                        %{
                          attribute_path: "schema_version",
                          attribute: "version",
                          value: version
                        }
                      )

                    true ->
                      # schema version is simply before - this might be OK so issue warning
                      add_warning(
                        response,
                        "version_earlier",
                        "Schema version \"#{version}\" at \"schema_version\" is earlier than" <>
                          " the current schema version \"#{schema_version}\"." <>
                          " Validating against later schema versions can yield deprecation" <>
                          " warnings and other (minor) validation messages that would not occur" <>
                          " when validating against the same version.",
                        %{
                          attribute_path: "schema_version",
                          attribute: "version",
                          value: version
                        }
                      )
                  end

                true ->
                  # Fallback... schema version is after (later/newer) than current schema version
                  add_error(
                    response,
                    "version_incompatible_later",
                    "Schema version \"#{version}\" at \"schema_version\" is incompatible with" <>
                      " the current schema version \"#{schema_version}\" because it is a later version." <>
                      " This can result in missing validation messages (false negatives)" <>
                      " and incorrect validation messages.",
                    %{
                      attribute_path: "schema_version",
                      attribute: "version",
                      value: version
                    }
                  )
              end
          end
      end
    else
      response
    end
  end

  @spec validate_constraints(map(), map(), map(), nil | String.t()) :: map()
  defp validate_constraints(response, input_item, schema_item, attribute_path) do
    if Map.has_key?(schema_item, :constraints) do
      Enum.reduce(
        schema_item[:constraints],
        response,
        fn {constraint_key, constraint_details}, response ->
          case constraint_key do
            :at_least_one ->
              # constraint_details is a list of keys where at least one must exist
              if Enum.any?(constraint_details, fn key -> Map.has_key?(input_item, key) end) do
                response
              else
                {description, extra} =
                  constraint_info(schema_item, attribute_path, constraint_key, constraint_details)

                add_error(
                  response,
                  "constraint_failed",
                  "Constraint failed: #{description};" <>
                    " expected at least one constraint attribute, but got none.",
                  extra
                )
              end

            :just_one ->
              # constraint_details is a list of keys where exactly one must exist
              count =
                Enum.reduce(
                  constraint_details,
                  0,
                  fn key, count ->
                    if Map.has_key?(input_item, key), do: count + 1, else: count
                  end
                )

              if count == 1 do
                response
              else
                {description, extra} =
                  constraint_info(schema_item, attribute_path, constraint_key, constraint_details)

                Map.put(extra, :value_count, count)

                add_error(
                  response,
                  "constraint_failed",
                  "Constraint failed: #{description};" <>
                    " expected exactly 1 constraint attribute, got #{count}.",
                  extra
                )
              end

            _ ->
              # This could be a new kind of constraint that this code needs to start handling,
              # or this a private schema / private extension has an unknown constraint type,
              # or its a typo in a private schema / private extension.
              {description, extra} =
                constraint_info(schema_item, attribute_path, constraint_key, constraint_details)

              Logger.warning("SCHEMA BUG: Unknown constraint #{description}")

              add_error(
                response,
                "constraint_unknown",
                "SCHEMA BUG: Unknown constraint #{description}.",
                extra
              )
          end
        end
      )
    else
      response
    end
  end

  # Helper to return class or object description and extra map
  @spec constraint_info(map(), String.t(), atom(), list(String.t())) :: {String.t(), map()}
  defp constraint_info(schema_item, attribute_path, constraint_key, constraint_details) do
    if attribute_path do
      # attribute_path exists (is not nil) for objects
      {
        "\"#{constraint_key}\" from object \"#{schema_item[:name]}\" at \"#{attribute_path}\"",
        %{
          attribute_path: attribute_path,
          constraint: %{constraint_key => constraint_details},
          object_name: schema_item[:name]
        }
      }
    else
      {
        "\"#{constraint_key}\" from class \"#{schema_item[:name]}\" uid #{schema_item[:uid]}",
        %{
          constraint: %{constraint_key => constraint_details},
          id: schema_item[:uid],
          class_name: schema_item[:name]
        }
      }
    end
  end

  # Validates attributes of input or object (input_item parameter)
  # against schema's class or object (schema_item parameter).
  @spec validate_attributes(
          map(),
          map(),
          nil | String.t(),
          map(),
          list(String.t()),
          list(),
          map(),
          boolean()
        ) :: map()
  defp validate_attributes(
         response,
         input_item,
         parent_attribute_path,
         schema_item,
         profiles,
         options,
         dictionary,
         is_enum
       ) do
    unless is_map(input_item) do
      # Not a map: add a type error for the object and skip further attribute validation
      attribute_name = schema_item[:name] || "object"
      attribute_path = parent_attribute_path || attribute_name

      add_error_wrong_type(
        response,
        attribute_path,
        attribute_name,
        input_item,
        "object"
      )
    else
      just_one_keys = schema_item[:constraints][:just_one] |> List.wrap()
      present_keys = Enum.filter(just_one_keys, &Map.has_key?(input_item, &1))

      schema_item =
        if length(present_keys) == 1 do
          present_key = hd(present_keys)

          filtered_attributes =
            Enum.filter(schema_item[:attributes], fn {k, _v} ->
              attr_name = Atom.to_string(k)
              # Keep if not in just_one_keys or is the present_key
              not Enum.member?(just_one_keys, attr_name) or attr_name == present_key
            end)

          %{schema_item | attributes: filtered_attributes}
        else
          schema_item
        end

      {response, schema_attributes} =
        if is_enum do
          if not is_map(input_item) do
            attribute_name = schema_item[:name] || "unknown_enum"
            attribute_path = make_attribute_path(parent_attribute_path, attribute_name)

            {
              add_error(
                response,
                "enum_object_not_matched",
                "The object provided for attribute \"#{attribute_path}\" is not a map/object.",
                %{
                  attribute_path: attribute_path,
                  attribute: attribute_name
                }
              ),
              []
            }
          else
            name = schema_item[:name]

            children =
              Schema.Utils.find_children(Schema.all_objects(), name)
              |> Enum.reject(fn item -> item[:hidden?] == true end)
              |> Enum.map(& &1[:name])
              |> Enum.map(&to_string/1)

            matching_child =
              children
              |> Enum.map(&Schema.entity_ex(:object, &1))
              |> Enum.find(fn child ->
                child_attrs = child[:attributes] || %{}

                required_keys =
                  child_attrs
                  |> Enum.filter(fn {_k, v} -> v[:requirement] == "required" end)
                  |> Enum.map(fn {k, _v} -> Atom.to_string(k) end)

                required_present? = Enum.all?(required_keys, &Map.has_key?(input_item, &1))
                child_attrs_map = Map.new(child_attrs)

                child_attr_keys =
                  child_attrs_map |> Map.keys() |> Enum.map(&Atom.to_string/1) |> MapSet.new()

                input_keys = Map.keys(input_item) |> MapSet.new()
                all_keys_present? = MapSet.subset?(input_keys, child_attr_keys)

                enums_match? =
                  Enum.all?(child_attrs, fn {attr_name, attr_def} ->
                    if Map.has_key?(attr_def, :enum) and
                         Map.has_key?(input_item, Atom.to_string(attr_name)) do
                      input_val = input_item[Atom.to_string(attr_name)]

                      input_val_atom =
                        if is_atom(input_val),
                          do: input_val,
                          else: String.to_atom(to_string(input_val))

                      input_val_str = to_string(input_val)

                      Map.has_key?(attr_def[:enum], input_val_atom) or
                        Map.has_key?(attr_def[:enum], input_val_str)
                    else
                      true
                    end
                  end)

                required_present? and all_keys_present? and enums_match?
              end)

            if matching_child do
              {response, filter_with_profiles(matching_child[:attributes], profiles)}
            else
              attribute_name = schema_item[:name] || "unknown_enum"
              attribute_path = make_attribute_path(parent_attribute_path, attribute_name)

              {
                add_error(
                  response,
                  "enum_object_not_matched",
                  "The object provided for attribute \"#{attribute_path}\" does not match any of allowed objects.",
                  %{
                    attribute_path: attribute_path,
                    attribute: attribute_name,
                    allowed_object_names: Enum.join(children, ", ")
                  }
                ),
                []
              }
            end
          end
        else
          {response, filter_with_profiles(schema_item[:attributes], profiles)}
        end

      response
      |> validate_attributes_types(
        input_item,
        parent_attribute_path,
        schema_attributes,
        profiles,
        options,
        dictionary
      )
      |> validate_attributes_unknown_keys(
        input_item,
        parent_attribute_path,
        schema_item,
        schema_attributes
      )
      |> validate_attributes_enums(input_item, parent_attribute_path, schema_attributes)
    end
  end

  # Validate unknown attributes
  # Scan input_item's attributes making sure each exists in schema_item's attributes
  @spec validate_attributes_types(
          map(),
          map(),
          nil | String.t(),
          list(tuple()),
          list(String.t()),
          list(),
          map()
        ) :: map()
  defp validate_attributes_types(
         response,
         input_item,
         parent_attribute_path,
         schema_attributes,
         profiles,
         options,
         dictionary
       ) do
    Enum.reduce(
      schema_attributes,
      response,
      fn {attribute_key, attribute_details}, response ->
        attribute_name = Atom.to_string(attribute_key)
        attribute_path = make_attribute_path(parent_attribute_path, attribute_name)
        value = input_item[attribute_name]

        validate_attribute(
          response,
          value,
          attribute_path,
          attribute_name,
          attribute_details,
          profiles,
          options,
          dictionary
        )
      end
    )
  end

  @spec validate_attributes_unknown_keys(
          map(),
          map(),
          nil | String.t(),
          map(),
          list(tuple())
        ) :: map()
  defp validate_attributes_unknown_keys(
         response,
         input_item,
         parent_attribute_path,
         schema_item,
         schema_attributes
       ) do
    if Enum.empty?(schema_attributes) do
      # This is class or object with no attributes defined. This is a special-case that means any
      # attributes are allowed. The object type "object" is the current example of this, and is
      # directly used by the "unmapped" and "xattributes" attributes as open-ended objects.
      response
    else
      Enum.reduce(
        Map.keys(input_item),
        response,
        fn key, response ->
          if has_attribute?(schema_attributes, key) do
            response
          else
            attribute_path = make_attribute_path(parent_attribute_path, key)

            {struct_desc, extra} =
              if Map.has_key?(schema_item, :uid) do
                {
                  "class \"#{schema_item[:name]}\" id #{schema_item[:uid]}",
                  %{
                    attribute_path: attribute_path,
                    attribute: key,
                    id: schema_item[:uid],
                    class_name: schema_item[:name]
                  }
                }
              else
                {
                  "object \"#{schema_item[:name]}\"",
                  %{
                    attribute_path: attribute_path,
                    attribute: key,
                    object_name: schema_item[:name]
                  }
                }
              end

            add_error(
              response,
              "attribute_unknown",
              "Unknown attribute at \"#{attribute_path}\";" <>
                " attribute \"#{key}\" is not defined in #{struct_desc}.",
              extra
            )
          end
        end
      )
    end
  end

  @spec has_attribute?(list(tuple()), String.t()) :: boolean()
  defp has_attribute?(attributes, name) do
    key = String.to_atom(name)
    Enum.any?(attributes, fn {attribute_key, _} -> attribute_key == key end)
  end

  @spec validate_attributes_enums(map(), map(), nil | String.t(), list(tuple())) :: map()
  defp validate_attributes_enums(response, input_item, parent_attribute_path, schema_attributes) do
    enum_attributes = Enum.filter(schema_attributes, fn {_ak, ad} -> Map.has_key?(ad, :enum) end)

    Enum.reduce(
      enum_attributes,
      response,
      fn {attribute_key, attribute_details}, response ->
        attribute_name = Atom.to_string(attribute_key)

        if Map.has_key?(input_item, attribute_name) do
          if attribute_details[:is_array] == true do
            {response, _} =
              Enum.reduce(
                input_item[attribute_name],
                {response, 0},
                fn value, {response, index} ->
                  value_atom =
                    cond do
                      is_atom(value) ->
                        value

                      is_binary(value) or is_integer(value) or is_float(value) ->
                        String.to_atom(to_string(value))

                      true ->
                        nil
                    end

                  if value_atom && Map.has_key?(attribute_details[:enum], value_atom) do
                    # The enum array value is good - check sibling and deprecation
                    response =
                      response
                      |> validate_enum_array_sibling(
                        input_item,
                        parent_attribute_path,
                        index,
                        value,
                        value_atom,
                        attribute_name,
                        attribute_details
                      )
                      |> validate_enum_array_value_deprecated(
                        parent_attribute_path,
                        index,
                        value,
                        value_atom,
                        attribute_name,
                        attribute_details
                      )

                    {response, index + 1}
                  else
                    attribute_path =
                      make_attribute_path(parent_attribute_path, attribute_name)
                      |> make_attribute_path_array_element(index)

                    response =
                      add_error(
                        response,
                        "attribute_enum_array_value_unknown",
                        "Unknown enum array value at \"#{attribute_path}\"; value" <>
                          " #{inspect(value)} is not defined for enum \"#{attribute_name}\".",
                        %{
                          attribute_path: attribute_path,
                          attribute: attribute_name,
                          value: value
                        }
                      )

                    {response, index + 1}
                  end
                end
              )

            response
          else
            # The enum values are always strings, so rather than use elaborate conversions,
            # we just use Kernel.to_string/1. (The value is type checked elsewhere anyway.)
            value = input_item[attribute_name]

            value_atom =
              cond do
                is_atom(value) ->
                  value

                is_binary(value) or is_integer(value) or is_float(value) ->
                  String.to_atom(to_string(value))

                true ->
                  nil
              end

            if value_atom && Map.has_key?(attribute_details[:enum], value_atom) do
              # The enum value is good - check sibling and deprecation
              response
              |> validate_enum_sibling(
                input_item,
                parent_attribute_path,
                value,
                value_atom,
                attribute_name,
                attribute_details
              )
              |> validate_enum_value_deprecated(
                parent_attribute_path,
                value,
                value_atom,
                attribute_name,
                attribute_details
              )
            else
              attribute_path = make_attribute_path(parent_attribute_path, attribute_name)

              add_error(
                response,
                "attribute_enum_value_unknown",
                "Unknown enum value at \"#{attribute_path}\";" <>
                  " value #{inspect(value)} is not defined for enum \"#{attribute_name}\".",
                %{
                  attribute_path: attribute_path,
                  attribute: attribute_name,
                  value: value
                }
              )
            end
          end
        else
          response
        end
      end
    )
  end

  @spec validate_enum_sibling(
          map(),
          map(),
          nil | String.t(),
          any(),
          atom(),
          String.t(),
          map()
        ) :: map()
  defp validate_enum_sibling(
         response,
         input_item,
         parent_attribute_path,
         input_enum_value,
         input_enum_value_atom,
         attribute_name,
         attribute_details
       ) do
    sibling_name = attribute_details[:sibling]

    if Map.has_key?(input_item, sibling_name) do
      # Sibling is present - make sure the string value matches up
      enum_caption = attribute_details[:enum][input_enum_value_atom][:caption]
      sibling_value = input_item[sibling_name]

      if input_enum_value == 99 do
        # Enum value is the integer 99 (Other). The enum sibling should _not_ match the
        if enum_caption == sibling_value do
          enum_attribute_path = make_attribute_path(parent_attribute_path, attribute_name)
          sibling_attribute_path = make_attribute_path(parent_attribute_path, sibling_name)

          add_warning(
            response,
            "attribute_enum_sibling_suspicious_other",
            "Attribute \"#{sibling_attribute_path}\" enum sibling value" <>
              " #{inspect(sibling_value)} suspiciously matches the caption of" <>
              " enum \"#{enum_attribute_path}\" value 99 (#{inspect(enum_caption)})." <>
              " Note: the recommendation is to use the original source value for" <>
              " 99 (#{inspect(enum_caption)}), so this should only match in the edge case" <>
              " where #{inspect(sibling_value)} is actually the original source value.",
            %{
              attribute_path: sibling_attribute_path,
              attribute: sibling_name,
              value: sibling_value
            }
          )
        else
          # The 99 (Other) sibling value looks good
          response
        end
      else
        if enum_caption == sibling_value do
          # Sibling has correct value
          response
        else
          enum_attribute_path = make_attribute_path(parent_attribute_path, attribute_name)
          sibling_attribute_path = make_attribute_path(parent_attribute_path, sibling_name)

          add_warning(
            response,
            "attribute_enum_sibling_incorrect",
            "Attribute \"#{sibling_attribute_path}\" enum sibling value" <>
              " #{inspect(sibling_value)} does not match the caption of" <>
              " enum \"#{enum_attribute_path}\" value #{inspect(input_enum_value)};" <>
              " expected \"#{enum_caption}\", got #{inspect(sibling_value)}." <>
              " Note: matching is recommended but not required.",
            %{
              attribute_path: sibling_attribute_path,
              attribute: sibling_name,
              value: sibling_value,
              expected_value: enum_caption
            }
          )
        end
      end
    else
      # Sibling not present, which is OK
      response
    end
  end

  @spec validate_enum_array_sibling(
          map(),
          map(),
          nil | String.t(),
          integer(),
          any(),
          atom(),
          String.t(),
          map()
        ) :: map()
  defp validate_enum_array_sibling(
         response,
         input_item,
         parent_attribute_path,
         index,
         input_enum_value,
         input_enum_value_atom,
         attribute_name,
         attribute_details
       ) do
    if input_enum_value == 99 do
      # Enum value is the integer 99 (Other). The enum sibling, if present, can be anything.
      response
    else
      sibling_name = attribute_details[:sibling]

      if Map.has_key?(input_item, sibling_name) do
        # Sibling array is present - make sure value exists and matches up
        enum_caption = attribute_details[:enum][input_enum_value_atom][:caption]
        sibling_array = input_item[sibling_name]
        sibling_value = Enum.at(sibling_array, index)

        if sibling_value == nil do
          enum_attribute_path =
            make_attribute_path(parent_attribute_path, attribute_name)
            |> make_attribute_path_array_element(index)

          sibling_attribute_path =
            make_attribute_path(parent_attribute_path, sibling_name)
            |> make_attribute_path_array_element(index)

          add_error(
            response,
            "attribute_enum_array_sibling_missing",
            "Attribute \"#{sibling_attribute_path}\" enum array sibling value" <>
              " is missing (array is not long enough) for" <>
              " enum array \"#{enum_attribute_path}\" value #{inspect(input_enum_value)}.",
            %{
              attribute_path: sibling_attribute_path,
              attribute: sibling_name,
              expected_value: enum_caption
            }
          )
        else
          if enum_caption == sibling_value do
            # Sibling has correct value
            response
          else
            enum_attribute_path =
              make_attribute_path(parent_attribute_path, attribute_name)
              |> make_attribute_path_array_element(index)

            sibling_attribute_path =
              make_attribute_path(parent_attribute_path, sibling_name)
              |> make_attribute_path_array_element(index)

            add_error(
              response,
              "attribute_enum_array_sibling_incorrect",
              "Attribute \"#{sibling_attribute_path}\" enum array sibling value" <>
                " #{inspect(sibling_value)} is incorrect for" <>
                " enum array \"#{enum_attribute_path}\" value #{inspect(input_enum_value)};" <>
                " expected \"#{enum_caption}\", got #{inspect(sibling_value)}.",
              %{
                attribute_path: sibling_attribute_path,
                attribute: sibling_name,
                value: sibling_value,
                expected_value: enum_caption
              }
            )
          end
        end
      else
        # Sibling not present, which is OK
        response
      end
    end
  end

  @spec validate_enum_value_deprecated(
          map(),
          nil | String.t(),
          any(),
          atom(),
          String.t(),
          map()
        ) :: map()
  defp validate_enum_value_deprecated(
         response,
         parent_attribute_path,
         input_enum_value,
         input_enum_value_atom,
         attribute_name,
         attribute_details
       ) do
    if Map.has_key?(attribute_details[:enum][input_enum_value_atom], :"@deprecated") do
      attribute_path = make_attribute_path(parent_attribute_path, attribute_name)
      deprecated = attribute_details[:enum][input_enum_value_atom][:"@deprecated"]

      add_warning(
        response,
        "attribute_enum_value_deprecated",
        "Deprecated enum value at \"#{attribute_path}\";" <>
          " value #{inspect(input_enum_value)} is deprecated. #{deprecated[:message]}",
        %{
          attribute_path: attribute_path,
          attribute: attribute_name,
          value: input_enum_value,
          since: deprecated[:since]
        }
      )
    else
      response
    end
  end

  @spec validate_enum_array_value_deprecated(
          map(),
          nil | String.t(),
          integer(),
          any(),
          atom(),
          String.t(),
          map()
        ) :: map()
  defp validate_enum_array_value_deprecated(
         response,
         parent_attribute_path,
         index,
         input_enum_value,
         input_enum_value_atom,
         attribute_name,
         attribute_details
       ) do
    if Map.has_key?(attribute_details[:enum][input_enum_value_atom], :"@deprecated") do
      attribute_path =
        make_attribute_path(parent_attribute_path, attribute_name)
        |> make_attribute_path_array_element(index)

      deprecated = attribute_details[:enum][input_enum_value_atom][:"@deprecated"]

      add_warning(
        response,
        "attribute_enum_array_value_deprecated",
        "Deprecated enum array value at \"#{attribute_path}\";" <>
          " value #{inspect(input_enum_value)} is deprecated. #{deprecated[:message]}",
        %{
          attribute_path: attribute_path,
          attribute: attribute_name,
          value: input_enum_value,
          since: deprecated[:since]
        }
      )
    else
      response
    end
  end

  @spec validate_attribute(
          map(),
          any(),
          String.t(),
          String.t(),
          map(),
          list(String.t()),
          list(),
          map()
        ) :: map()
  defp validate_attribute(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_details,
         profiles,
         options,
         dictionary
       ) do
    if value == nil do
      validate_requirement(
        response,
        attribute_path,
        attribute_name,
        attribute_details,
        options
      )
    else
      response =
        validate_attribute_deprecated(
          response,
          attribute_path,
          attribute_name,
          attribute_details
        )

      # Check input_item attribute value type
      attribute_type_key = String.to_atom(attribute_details[:type])

      if attribute_type_key == :object_t or
           Map.has_key?(dictionary[:types][:attributes], attribute_type_key) do
        if attribute_details[:is_array] do
          validate_array(
            response,
            value,
            attribute_path,
            attribute_name,
            attribute_details,
            profiles,
            options,
            dictionary
          )
        else
          validate_value(
            response,
            value,
            attribute_path,
            attribute_name,
            attribute_details,
            profiles,
            options,
            dictionary
          )
        end
      else
        # This should never happen for published schemas (validator will catch this) but
        # _could_ happen for a schema that's in development and presumably running on a
        # local / private OASF Server instance.
        Logger.warning(
          "SCHEMA BUG: Type \"#{attribute_type_key}\" is not defined in dictionary" <>
            " at attribute path \"#{attribute_path}\""
        )

        add_error(
          response,
          "schema_bug_type_missing",
          "SCHEMA BUG: Type \"#{attribute_type_key}\" is not defined in dictionary.",
          %{
            attribute_path: attribute_path,
            attribute: attribute_name,
            type: attribute_type_key,
            value: value
          }
        )
      end
    end
  end

  defp validate_requirement(
         response,
         attribute_path,
         attribute_name,
         attribute_details,
         options
       ) do
    case attribute_details[:requirement] do
      "required" ->
        add_error_required_attribute_missing(response, attribute_path, attribute_name)

      "recommended" ->
        if Keyword.get(options, :warn_on_missing_recommended) do
          add_warning_recommended_attribute_missing(response, attribute_path, attribute_name)
        else
          response
        end

      _ ->
        response
    end
  end

  # validate an attribute whose value should be an array (is_array: true)
  @spec validate_array(
          map(),
          any(),
          String.t(),
          String.t(),
          map(),
          list(String.t()),
          list(),
          map()
        ) :: map()
  defp validate_array(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_details,
         profiles,
         options,
         dictionary
       ) do
    if is_list(value) do
      # Check if array is empty for required attributes
      response =
        if Enum.empty?(value) and attribute_details[:requirement] == "required" do
          add_error(
            response,
            "attribute_required_empty",
            "Required array attribute \"#{attribute_path}\" is empty.",
            %{attribute_path: attribute_path, attribute: attribute_name}
          )
        else
          response
        end

      # Check for duplicates in array
      response =
        check_array_duplicates(
          response,
          value,
          attribute_path,
          attribute_name,
          attribute_details
        )

      # Check for duplicate types in locators array
      response =
        if attribute_name == "locators" do
          check_locators_duplicate_types(response, value, attribute_path, attribute_name)
        else
          response
        end

      {response, _} =
        Enum.reduce(
          value,
          {response, 0},
          fn element_value, {response, index} ->
            {
              validate_value(
                response,
                element_value,
                make_attribute_path_array_element(attribute_path, index),
                attribute_name,
                attribute_details,
                profiles,
                options,
                dictionary
              ),
              index + 1
            }
          end
        )

      response
    else
      add_error_wrong_type(
        response,
        attribute_path,
        attribute_name,
        value,
        "array of #{attribute_details[:type]}"
      )
    end
  end

  # validate a single value or element of an array (attribute with is_array: true)
  @spec validate_value(
          map(),
          any(),
          String.t(),
          String.t(),
          map(),
          list(String.t()),
          list(),
          map()
        ) :: map()
  defp validate_value(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_details,
         profiles,
         options,
         dictionary
       ) do
    attribute_type = attribute_details[:type]

    case attribute_type do
      "class_t" ->
        # class_t is a marker added by the schema compile to make it easy to check if attribute
        # is an OASF class (otherwise we would need to notice that the attribute type isn't a
        # data dictionary type)
        {response, class} =
          case attribute_details[:family] do
            "skill" ->
              validate_class_id_or_name(
                response,
                value,
                attribute_path,
                &Schema.find_skill/1,
                &Schema.skill/1
              )

            "domain" ->
              validate_class_id_or_name(
                response,
                value,
                attribute_path,
                &Schema.find_domain/1,
                &Schema.domain/1
              )

            "module" ->
              validate_class_id_or_name(
                response,
                value,
                attribute_path,
                &Schema.find_module/1,
                &Schema.module/1
              )

            _ ->
              # This should never happen for published schemas (validator will catch this) but
              # _could_ happen for a schema that's in development and presumably running on a
              # local / private OASF Server instance.
              Logger.warning(
                "SCHEMA BUG: Class type \"#{attribute_type}\" is not defined in dictionary" <>
                  " at attribute path \"#{attribute_path}\""
              )

              add_error(
                response,
                "schema_bug_class_missing",
                "SCHEMA BUG: Class type \"#{attribute_type}\" is not defined in dictionary.",
                %{
                  attribute_path: attribute_path,
                  attribute: attribute_name,
                  type: attribute_type,
                  value: value
                }
              )
          end

        if class do
          response =
            check_base_class_error(
              response,
              class,
              value,
              attribute_path,
              attribute_name,
              attribute_details[:family]
            )

          {response, profiles} = validate_and_return_profiles(response, value)

          validate_input_against_class(
            response,
            value,
            class,
            profiles,
            options,
            dictionary,
            attribute_path
          )
        else
          # Can't continue if we can't find the class
          response
        end

      "object_t" ->
        # object_t is a marker added by the schema compile to make it easy to check if attribute
        # is an OASF object (otherwise we would need to notice that the attribute type isn't a
        # data dictionary type)
        object_type = attribute_details[:object_type]

        validate_map_against_object(
          response,
          value,
          attribute_path,
          attribute_name,
          Schema.object(object_type),
          profiles,
          options,
          dictionary,
          attribute_details[:is_enum] || false
        )

      _ ->
        validate_value_against_dictionary_type(
          response,
          value,
          attribute_path,
          attribute_name,
          attribute_details,
          dictionary
        )
    end
  end

  @spec validate_map_against_object(
          map(),
          map(),
          String.t(),
          String.t(),
          map(),
          list(String.t()),
          list(),
          map(),
          boolean()
        ) :: map()
  defp validate_map_against_object(
         response,
         input_object,
         attribute_path,
         attribute_name,
         schema_object,
         profiles,
         options,
         dictionary,
         is_enum
       ) do
    response
    |> validate_object_deprecated(attribute_path, attribute_name, schema_object)
    |> validate_attributes(
      input_object,
      attribute_path,
      schema_object,
      profiles,
      options,
      dictionary,
      is_enum
    )
    |> validate_constraints(input_object, schema_object, attribute_path)
  end

  @spec validate_object_deprecated(map(), String.t(), String.t(), map()) :: map()
  defp validate_object_deprecated(response, attribute_path, attribute_name, schema_object) do
    if Map.has_key?(schema_object, :"@deprecated") do
      add_warning_object_deprecated(response, attribute_path, attribute_name, schema_object)
    else
      response
    end
  end

  @spec validate_value_against_dictionary_type(
          map(),
          any(),
          String.t(),
          String.t(),
          map(),
          map()
        ) :: map()
  defp validate_value_against_dictionary_type(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_details,
         dictionary
       ) do
    attribute_type_key = String.to_atom(attribute_details[:type])
    dictionary_types = dictionary[:types][:attributes]
    dictionary_type = dictionary_types[attribute_type_key]

    {primitive_type, expected_type, expected_type_extra} =
      if Map.has_key?(dictionary_type, :type) do
        # This is a subtype (e.g., username_t, a subtype of string_t)
        primitive_type = String.to_atom(dictionary_type[:type])
        {primitive_type, attribute_type_key, " (#{primitive_type})"}
      else
        # This is a primitive type
        {attribute_type_key, attribute_type_key, ""}
      end

    case primitive_type do
      :boolean_t ->
        if is_boolean(value) do
          validate_type_values(
            response,
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      :float_t ->
        if is_float(value) do
          response
          |> validate_number_range(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
          |> validate_type_values(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      :integer_t ->
        if is_integer_t(value) do
          response
          |> validate_number_range(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
          |> validate_type_values(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      :json_t ->
        response

      :typed_map_t ->
        if is_map(value) do
          response
          |> validate_typed_map(
            value,
            attribute_path,
            attribute_name,
            attribute_details,
            dictionary
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      :long_t ->
        if is_long_t(value) do
          response
          |> validate_number_range(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
          |> validate_type_values(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      :string_t ->
        if is_binary(value) do
          response
          |> validate_string_max_len(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
          |> validate_string_regex(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
          |> validate_type_values(
            value,
            attribute_path,
            attribute_name,
            attribute_type_key,
            dictionary_types
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            expected_type,
            expected_type_extra
          )
        end

      _ ->
        # Unhandled type (schema bug)
        # This should never happen for published schemas (OASF-validator catches this) but
        # _could_ happen for a schema that's in development or with a private extension,
        # and presumably running on a local / private OASF Server instance.
        Logger.warning(
          "SCHEMA BUG: Unknown primitive type \"#{primitive_type}\"" <>
            " at attribute path \"#{attribute_path}\""
        )

        add_error(
          response,
          "schema_bug_primitive_type_unknown",
          "SCHEMA BUG: Unknown primitive type \"#{primitive_type}\".",
          %{
            attribute_path: attribute_path,
            attribute: attribute_name,
            type: attribute_type_key,
            value: value
          }
        )
    end
  end

  @spec validate_type_values(
          map(),
          any(),
          String.t(),
          String.t(),
          atom(),
          map()
        ) :: map()
  defp validate_type_values(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_type_key,
         dictionary_types
       ) do
    dictionary_type = dictionary_types[attribute_type_key]

    cond do
      Map.has_key?(dictionary_type, :values) ->
        # This is a primitive type or subtype with :values
        values = dictionary_type[:values]

        if Enum.any?(values, fn v -> value == v end) do
          response
        else
          add_error(
            response,
            "attribute_value_not_in_type_values",
            "Attribute \"#{attribute_path}\" value" <>
              " is not in type \"#{attribute_type_key}\" list of allowed values.",
            %{
              attribute_path: attribute_path,
              attribute: attribute_name,
              type: attribute_type_key,
              value: value,
              allowed_values: values
            }
          )
        end

      Map.has_key?(dictionary_type, :type) ->
        # This is a subtype, so check super type
        super_type_key = String.to_atom(dictionary_type[:type])
        super_type = dictionary_types[super_type_key]

        if Map.has_key?(super_type, :values) do
          values = super_type[:values]

          if Enum.any?(values, fn v -> value == v end) do
            response
          else
            add_error(
              response,
              "attribute_value_not_in_super_type_values",
              "Attribute \"#{attribute_path}\", type \"#{attribute_type_key}\"," <>
                " value is not in super type \"#{super_type_key}\" list of allowed values.",
              %{
                attribute_path: attribute_path,
                attribute: attribute_name,
                super_type: super_type_key,
                type: attribute_type_key,
                value: value,
                allowed_values: values
              }
            )
          end
        else
          response
        end

      true ->
        response
    end
  end

  # Validate a number against a possible range constraint.
  # If attribute_type_key refers to a subtype, the subtype is checked first, and if the subtype
  # doesn't have a range, the supertype is checked.
  @spec validate_number_range(
          map(),
          float() | integer(),
          String.t(),
          String.t(),
          atom(),
          map()
        ) :: map()
  defp validate_number_range(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_type_key,
         dictionary_types
       ) do
    dictionary_type = dictionary_types[attribute_type_key]

    cond do
      Map.has_key?(dictionary_type, :range) ->
        # This is a primitive type or subtype with a range
        [low, high] = dictionary_type[:range]

        if value < low or value > high do
          add_error(
            response,
            "attribute_value_exceeds_range",
            "Attribute \"#{attribute_path}\" value" <>
              " is outside type \"#{attribute_type_key}\" range of #{low} to #{high}.",
            %{
              attribute_path: attribute_path,
              attribute: attribute_name,
              type: attribute_type_key,
              value: value,
              range: [low, high]
            }
          )
        else
          response
        end

      Map.has_key?(dictionary_type, :type) ->
        # This is a subtype, so check super type
        super_type_key = String.to_atom(dictionary_type[:type])
        super_type = dictionary_types[super_type_key]

        if Map.has_key?(super_type, :range) do
          [low, high] = super_type[:range]

          if value < low or value > high do
            add_error(
              response,
              "attribute_value_exceeds_super_type_range",
              "Attribute \"#{attribute_path}\", type \"#{attribute_type_key}\"," <>
                " value is outside super type \"#{super_type_key}\" range of #{low} to #{high}.",
              %{
                attribute_path: attribute_path,
                attribute: attribute_name,
                super_type: super_type_key,
                type: attribute_type_key,
                value: value,
                super_type_range: [low, high]
              }
            )
          else
            response
          end
        else
          response
        end

      true ->
        response
    end
  end

  # Validate a string against a possible max_len constraint.
  # If attribute_type_key refers to a subtype, the subtype is checked first, and if the subtype
  # doesn't have a max_len, the supertype is checked.
  @spec validate_string_max_len(
          map(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          map()
        ) :: map()
  defp validate_string_max_len(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_type_key,
         dictionary_types
       ) do
    dictionary_type = dictionary_types[attribute_type_key]

    cond do
      Map.has_key?(dictionary_type, :max_len) ->
        # This is a primitive type or subtype with a range
        max_len = dictionary_type[:max_len]
        len = String.length(value)

        if len > max_len do
          add_error(
            response,
            "attribute_value_exceeds_max_len",
            "Attribute \"#{attribute_path}\" value length of #{len}" <>
              " exceeds type \"#{attribute_type_key}\" max length #{max_len}.",
            %{
              attribute_path: attribute_path,
              attribute: attribute_name,
              type: attribute_type_key,
              length: len,
              max_len: max_len,
              value: value
            }
          )
        else
          response
        end

      Map.has_key?(dictionary_type, :type) ->
        # This is a subtype, so check super type
        super_type_key = String.to_atom(dictionary_type[:type])
        super_type = dictionary_types[super_type_key]

        if Map.has_key?(super_type, :max_len) do
          max_len = super_type[:max_len]
          len = String.length(value)

          if len > max_len do
            add_error(
              response,
              "attribute_value_exceeds_super_type_max_len",
              "Attribute \"#{attribute_path}\", type \"#{attribute_type_key}\"," <>
                " value length #{len} exceeds super type \"#{super_type_key}\"" <>
                " max length #{max_len}.",
              %{
                attribute_path: attribute_path,
                attribute: attribute_name,
                super_type: super_type_key,
                type: attribute_type_key,
                length: len,
                max_len: max_len,
                value: value
              }
            )
          else
            response
          end
        else
          response
        end

      true ->
        response
    end
  end

  defp validate_string_regex(
         response,
         value,
         attribute_path,
         attribute_name,
         attribute_type_key,
         dictionary_types
       ) do
    dictionary_type = dictionary_types[attribute_type_key]

    cond do
      Map.has_key?(dictionary_type, :regex) ->
        # This is a primitive type or subtype with a range
        regex = dictionary_type[:regex]

        case Regex.compile(regex) do
          {:ok, compiled_regex} ->
            if Regex.match?(compiled_regex, value) do
              response
            else
              add_warning(
                response,
                "attribute_value_regex_not_matched",
                "Attribute \"#{attribute_path}\" value" <>
                  " does not match regex of type \"#{attribute_type_key}\".",
                %{
                  attribute_path: attribute_path,
                  attribute: attribute_name,
                  type: attribute_type_key,
                  regex: regex,
                  value: value
                }
              )
            end

          {:error, {message, position}} ->
            Logger.warning(
              "SCHEMA BUG: Type \"#{attribute_type_key}\" specifies an invalid regex:" <>
                " \"#{message}\" at position #{position}, attribute path \"#{attribute_path}\""
            )

            add_error(
              response,
              "schema_bug_type_regex_invalid",
              "SCHEMA BUG: Type \"#{attribute_type_key}\" specifies an invalid regex:" <>
                " \"#{message}\" at position #{position}.",
              %{
                attribute_path: attribute_path,
                attribute: attribute_name,
                type: attribute_type_key,
                regex: regex,
                regex_error_message: to_string(message),
                regex_error_position: position
              }
            )
        end

      Map.has_key?(dictionary_type, :type) ->
        # This is a subtype, so check super type
        super_type_key = String.to_atom(dictionary_type[:type])
        super_type = dictionary_types[super_type_key]

        if Map.has_key?(super_type, :regex) do
          regex = dictionary_type[:regex]

          case Regex.compile(regex) do
            {:ok, compiled_regex} ->
              if Regex.match?(compiled_regex, value) do
                response
              else
                add_warning(
                  response,
                  "attribute_value_super_type_regex_not_matched",
                  "Attribute \"#{attribute_path}\", type \"#{attribute_type_key}\"," <>
                    " value does not match regex of super type \"#{super_type_key}\".",
                  %{
                    attribute_path: attribute_path,
                    attribute: attribute_name,
                    super_type: super_type_key,
                    type: attribute_type_key,
                    regex: regex,
                    value: value
                  }
                )
              end

            {:error, {message, position}} ->
              Logger.warning(
                "SCHEMA BUG: Type \"#{super_type_key}\"" <>
                  " (super type of \"#{attribute_type_key}\") specifies an invalid regex:" <>
                  " \"#{message}\" at position #{position}, attribute path \"#{attribute_path}\""
              )

              add_error(
                response,
                "schema_bug_type_regex_invalid",
                "SCHEMA BUG: Type \"#{super_type_key}\"" <>
                  " (super type of \"#{attribute_type_key}\") specifies an invalid regex:" <>
                  " \"#{message}\" at position #{position}.",
                %{
                  attribute_path: attribute_path,
                  attribute: attribute_name,
                  type: super_type_key,
                  regex: regex,
                  regex_error_message: to_string(message),
                  regex_error_position: position
                }
              )
          end
        else
          response
        end

      true ->
        response
    end
  end

  # Validate a map with string key and configurable value types.
  @spec validate_typed_map(
          map(),
          map(),
          String.t(),
          String.t(),
          map(),
          map()
        ) :: map()
  defp validate_typed_map(
         response,
         json_object,
         attribute_path,
         attribute_name,
         attribute_details,
         dictionary
       ) do
    value_type = Map.get(attribute_details, :value_type, "string_t")

    Enum.reduce(json_object, response, fn {key, value}, acc_response ->
      if is_binary(key) do
        validate_typed_value(
          value,
          value_type,
          dictionary,
          acc_response,
          attribute_path,
          attribute_name,
          key
        )
      else
        add_error_wrong_type(
          response,
          attribute_path,
          attribute_name,
          value,
          "string",
          ""
        )
      end
    end)
  end

  defp validate_typed_value(
         value,
         type_string,
         dictionary,
         response,
         attribute_path,
         attribute_name,
         key
       ) do
    case Schema.object(type_string) do
      nil ->
        attribute_details = %{type: type_string}

        validate_value_against_dictionary_type(
          response,
          value,
          "#{attribute_path}.#{key}",
          attribute_name,
          attribute_details,
          dictionary
        )

      object ->
        if is_map(value) do
          validate_map_against_object(
            response,
            value,
            "#{attribute_path}.#{key}",
            attribute_name,
            object,
            [],
            [],
            dictionary,
            false
          )
        else
          add_error_wrong_type(
            response,
            attribute_path,
            attribute_name,
            value,
            "#{type_string} (object)",
            ""
          )
        end
    end
  end

  defp validate_attribute_deprecated(response, attribute_path, attribute_name, attribute_details) do
    if Map.has_key?(attribute_details, :"@deprecated") do
      add_warning_attribute_deprecated(
        response,
        attribute_path,
        attribute_name,
        attribute_details
      )
    else
      response
    end
  end

  @spec make_attribute_path(nil | String.t(), String.t()) :: String.t()
  defp make_attribute_path(parent_attribute_path, attribute_name) do
    if parent_attribute_path != nil and parent_attribute_path != "" do
      "#{parent_attribute_path}.#{attribute_name}"
    else
      attribute_name
    end
  end

  @spec make_attribute_path_array_element(String.t(), integer()) :: String.t()
  defp make_attribute_path_array_element(attribute_path, index) do
    "#{attribute_path}[#{index}]"
  end

  @spec new_response(map()) :: map()
  defp new_response(input) do
    metadata = input["metadata"]

    if is_map(metadata) do
      uid = metadata["uid"]

      if is_binary(uid) do
        %{uid: uid}
      else
        %{}
      end
    else
      %{}
    end
  end

  @spec add_error_required_attribute_missing(map(), String.t(), String.t()) :: map()
  defp add_error_required_attribute_missing(response, attribute_path, attribute_name) do
    add_error(
      response,
      "attribute_required_missing",
      "Required attribute \"#{attribute_path}\" is missing.",
      %{attribute_path: attribute_path, attribute: attribute_name}
    )
  end

  @spec add_warning_recommended_attribute_missing(map(), String.t(), String.t()) :: map()
  defp add_warning_recommended_attribute_missing(response, attribute_path, attribute_name) do
    add_warning(
      response,
      "attribute_recommended_missing",
      "Recommended attribute \"#{attribute_path}\" is missing.",
      %{attribute_path: attribute_path, attribute: attribute_name}
    )
  end

  @spec add_error_wrong_type(
          map(),
          String.t(),
          String.t(),
          any(),
          atom() | String.t(),
          String.t()
        ) :: map()
  defp add_error_wrong_type(
         response,
         attribute_path,
         attribute_name,
         value,
         expected_type,
         expected_type_extra \\ ""
       ) do
    {value_type, value_type_extra} = type_of(value)

    add_error(
      response,
      "attribute_wrong_type",
      "Attribute \"#{attribute_path}\" value has wrong type;" <>
        " expected #{expected_type}#{expected_type_extra}, got #{value_type}#{value_type_extra}.",
      %{
        attribute_path: attribute_path,
        attribute: attribute_name,
        value: value,
        value_type: value_type,
        expected_type: expected_type
      }
    )
  end

  @spec add_warning_class_deprecated(map(), map()) :: map()
  defp add_warning_class_deprecated(response, class) do
    deprecated = class[:"@deprecated"]

    add_warning(
      response,
      "class_deprecated",
      "Class \"#{class[:name]}\" id #{class[:uid]} is deprecated. #{deprecated[:message]}",
      %{id: class[:uid], name: class[:name], since: deprecated[:since]}
    )
  end

  @spec add_warning_attribute_deprecated(map(), String.t(), String.t(), map()) :: map()
  defp add_warning_attribute_deprecated(
         response,
         attribute_path,
         attribute_name,
         attribute_details
       ) do
    deprecated = attribute_details[:"@deprecated"]

    add_warning(
      response,
      "attribute_deprecated",
      "Attribute \"#{attribute_name}\" is deprecated. #{deprecated[:message]}",
      %{attribute_path: attribute_path, attribute: attribute_name, since: deprecated[:since]}
    )
  end

  @spec add_warning_object_deprecated(map(), String.t(), String.t(), map()) :: map()
  defp add_warning_object_deprecated(response, attribute_path, attribute_name, object) do
    deprecated = object[:"@deprecated"]

    add_warning(
      response,
      "object_deprecated",
      "Object \"#{object[:name]}\" is deprecated. #{deprecated[:message]}",
      %{
        attribute_path: attribute_path,
        attribute: attribute_name,
        object_name: object[:name],
        since: deprecated[:since]
      }
    )
  end

  @spec check_base_class_error(map(), map(), map(), String.t(), String.t(), String.t()) :: map()
  defp check_base_class_error(response, class, value, attribute_path, attribute_name, family) do
    class_name = class[:name]
    # Normalize class name to string for comparison (it may be an atom)
    class_name_str = if is_atom(class_name), do: Atom.to_string(class_name), else: class_name

    base_class_name =
      case family do
        "skill" -> "base_skill"
        "domain" -> "base_domain"
        "module" -> "base_module"
        _ -> nil
      end

    # Check if name matches base class name
    name_matches = base_class_name && class_name_str == base_class_name

    # Check if ID is 0 (base classes have UID 0)
    # Only check ID if it was provided in the input value
    id_is_zero =
      if Map.has_key?(value, "id") do
        input_id = value["id"]
        # Check if input ID is 0 (could be integer 0 or string "0")
        cond do
          is_integer(input_id) && input_id == 0 ->
            true

          is_bitstring(input_id) ->
            case Integer.parse(input_id) do
              {parsed_id, _} -> parsed_id == 0
              :error -> false
            end

          true ->
            false
        end
      else
        false
      end

    if base_class_name && (name_matches || id_is_zero) do
      add_error(
        response,
        "base_class_used",
        "\"#{base_class_name}\" is used at \"#{attribute_path}\". " <>
          "\"#{base_class_name}\" is not valid option for this attribute; please specify a concrete #{family}.",
        %{
          attribute_path: attribute_path,
          attribute: attribute_name,
          value: base_class_name
        }
      )
    else
      response
    end
  end

  @spec add_error(map(), String.t(), String.t(), map()) :: map()
  defp add_error(response, error_type, message, extra) do
    _add(response, :errors, :error, error_type, message, extra)
  end

  @spec add_warning(map(), String.t(), String.t(), map()) :: map()
  defp add_warning(response, warning_type, message, extra) do
    _add(response, :warnings, :warning, warning_type, message, extra)
  end

  @spec _add(map(), atom(), atom(), String.t(), String.t(), map()) :: map()
  defp _add(response, group_key, type_key, type, message, extra) do
    item = Map.merge(extra, %{type_key => type, message: message})
    Map.update(response, group_key, [item], fn items -> [item | items] end)
  end

  @spec finalize_response(map()) :: map()
  defp finalize_response(response) do
    # Reverse errors and warning so they are the order they were found,
    # which is (probably) more sensible than the reverse
    errors = lenient_reverse(response[:errors])
    warnings = lenient_reverse(response[:warnings])

    response =
      Map.merge(response, %{
        error_count: length(errors),
        warning_count: length(warnings),
        errors: errors,
        warnings: warnings
      })

    sanitize_for_json(response)
  end

  defp lenient_reverse(nil), do: []
  defp lenient_reverse(list) when is_list(list), do: Enum.reverse(list)

  # Recursively convert tuples in the response to lists (for JSON encoding)
  defp sanitize_for_json(term) when is_tuple(term) do
    Tuple.to_list(term)
  end

  defp sanitize_for_json(term) when is_map(term) do
    Map.new(term, fn {k, v} -> {k, sanitize_for_json(v)} end)
  end

  defp sanitize_for_json(term) when is_list(term) do
    Enum.map(term, &sanitize_for_json/1)
  end

  defp sanitize_for_json(term), do: term

  # Returns approximate OASF type as a string for a value parsed from JSON. This is intended for
  # use when an attribute's type is incorrect. For integer values, this returns smallest type that
  # can be used for value.
  @spec type_of(any()) :: {String.t(), String.t()}
  defp type_of(v) do
    cond do
      is_float(v) ->
        # Elixir / Erlang floats are 64-bit IEEE floating point numbers, same as OASF
        {"float_t", ""}

      is_integer(v) ->
        # Elixir / Erlang has arbitrary-precision integers, so we need to test the range
        cond do
          is_integer_t(v) ->
            {"integer_t", " (integer in range of -2^63 to 2^63 - 1)"}

          is_long_t(v) ->
            {"long_t", " (integer in range of -2^127 to 2^127 - 1)"}

          true ->
            {"big integer", " (outside of long_t range of -2^127 to 2^127 - 1)"}
        end

      is_boolean(v) ->
        {"boolean_t", ""}

      is_binary(v) ->
        {"string_t", ""}

      is_list(v) ->
        {"array", ""}

      is_map(v) ->
        {"object", ""}

      v == nil ->
        {"null", ""}

      true ->
        {"unknown type", ""}
    end
  end

  @min_int -Integer.pow(2, 63)
  @max_int Integer.pow(2, 63) - 1

  # Tests if value is an integer number in the OASF integer_t range.
  defp is_integer_t(v) when is_integer(v), do: v >= @min_int && v <= @max_int
  defp is_integer_t(_), do: false

  @min_long -Integer.pow(2, 127)
  @max_long Integer.pow(2, 127) - 1

  # Tests if value is an integer number in the OASF long_t range.
  defp is_long_t(v) when is_integer(v), do: v >= @min_long && v <= @max_long
  defp is_long_t(_), do: false

  # Check for duplicate items in an array
  @spec check_array_duplicates(map(), list(), String.t(), String.t(), map()) :: map()
  defp check_array_duplicates(
         response,
         array,
         attribute_path,
         attribute_name,
         attribute_details
       ) do
    # For class_t types, we need to resolve to class UID for comparison
    # For other types, use deep equality comparison
    is_class_t = attribute_details[:type] == "class_t"

    {response, _} =
      Enum.reduce(array, {response, {[], 0}}, fn element, {response, {seen, index}} ->
        comparison_key =
          if is_class_t do
            # Resolve class reference to UID for comparison
            resolve_class_uid(element, attribute_details)
          else
            # Normalize element for comparison (convert to JSON-like structure)
            normalize_for_comparison(element)
          end

        # Check if this comparison key already exists in seen list
        first_index =
          Enum.find_index(seen, fn seen_item ->
            if is_class_t do
              # For class_t, compare UIDs directly
              seen_item == comparison_key
            else
              # For other types, use deep equality
              values_equal?(seen_item, comparison_key)
            end
          end)

        if first_index && comparison_key != nil do
          # Found a duplicate (only report if comparison_key is valid)
          duplicate_path = make_attribute_path_array_element(attribute_path, index)

          response =
            add_error(
              response,
              "attribute_array_duplicate",
              "Duplicate item found in array \"#{attribute_path}\" at index #{index}." <>
                " First occurrence at index #{first_index}.",
              %{
                attribute_path: duplicate_path,
                attribute: attribute_name,
                duplicate_index: index,
                first_index: first_index
              }
            )

          {response, {seen, index + 1}}
        else
          # Add to seen list if comparison_key is valid (nil means resolution failed, will be caught by validation)
          if comparison_key != nil do
            {response, {[comparison_key | seen], index + 1}}
          else
            {response, {seen, index + 1}}
          end
        end
      end)

    response
  end

  # Resolve a class reference (by id or name) to its UID
  @spec resolve_class_uid(map(), map()) :: nil | integer()
  defp resolve_class_uid(element, attribute_details) when is_map(element) do
    family = attribute_details[:family]

    # Determine the find functions based on family
    {find_by_id_fn, find_by_name_fn} =
      case family do
        "skill" -> {&Schema.find_skill/1, &Schema.skill/1}
        "domain" -> {&Schema.find_domain/1, &Schema.domain/1}
        "module" -> {&Schema.find_module/1, &Schema.module/1}
        _ -> {nil, nil}
      end

    if find_by_id_fn && find_by_name_fn do
      # Try to resolve by ID first
      class_by_id =
        if Map.has_key?(element, "id") do
          id = element["id"]
          if is_integer(id), do: find_by_id_fn.(id), else: nil
        else
          nil
        end

      # Try to resolve by name
      class_by_name =
        if Map.has_key?(element, "name") do
          name = Schema.Utils.descope(element["name"])
          if is_binary(name), do: find_by_name_fn.(name), else: nil
        else
          nil
        end

      # Return UID if we found a class
      cond do
        class_by_id -> class_by_id.uid
        class_by_name -> class_by_name.uid
        true -> nil
      end
    else
      nil
    end
  end

  defp resolve_class_uid(_element, _attribute_details), do: nil

  # Normalize a value for comparison (convert to JSON-serializable structure)
  @spec normalize_for_comparison(any()) :: any()
  defp normalize_for_comparison(value) when is_map(value) do
    # Sort map keys and recursively normalize values
    value
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> {k, normalize_for_comparison(v)} end)
    |> Enum.into(%{})
  end

  defp normalize_for_comparison(value) when is_list(value) do
    Enum.map(value, &normalize_for_comparison/1)
  end

  defp normalize_for_comparison(value) when is_atom(value) do
    Atom.to_string(value)
  end

  defp normalize_for_comparison(value) do
    value
  end

  # Deep equality check for normalized values
  @spec values_equal?(any(), any()) :: boolean()
  defp values_equal?(a, b) when is_map(a) and is_map(b) do
    if map_size(a) == map_size(b) do
      Enum.all?(a, fn {k, v} ->
        Map.has_key?(b, k) and values_equal?(v, b[k])
      end)
    else
      false
    end
  end

  defp values_equal?(a, b) when is_list(a) and is_list(b) do
    if length(a) == length(b) do
      Enum.zip(a, b) |> Enum.all?(fn {x, y} -> values_equal?(x, y) end)
    else
      false
    end
  end

  defp values_equal?(a, b), do: a == b

  # Check for duplicate types in locators array
  @spec check_locators_duplicate_types(map(), list(), String.t(), String.t()) :: map()
  defp check_locators_duplicate_types(response, array, attribute_path, attribute_name) do
    {response, _} =
      Enum.reduce(array, {response, {%{}, 0}}, fn element, {response, {seen_types, index}} ->
        if is_map(element) and Map.has_key?(element, "type") do
          locator_type = element["type"]

          if Map.has_key?(seen_types, locator_type) do
            first_index = seen_types[locator_type]
            duplicate_path = make_attribute_path_array_element(attribute_path, index)

            response =
              add_error(
                response,
                "attribute_locators_duplicate_type",
                "Duplicate locator type \"#{locator_type}\" found in array \"#{attribute_path}\" at index #{index}." <>
                  " First occurrence at index #{first_index}. Duplicate types are not allowed in the locators array.",
                %{
                  attribute_path: duplicate_path,
                  attribute: attribute_name,
                  duplicate_index: index,
                  first_index: first_index,
                  locator_type: locator_type
                }
              )

            {response, {seen_types, index + 1}}
          else
            {response, {Map.put(seen_types, locator_type, index), index + 1}}
          end
        else
          {response, {seen_types, index + 1}}
        end
      end)

    response
  end
end
