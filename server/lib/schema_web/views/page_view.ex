# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.PageView do
  alias SchemaWeb.SchemaController
  use SchemaWeb, :view

  require Logger

  @at_least_one_symbol "†"
  @just_one_symbol "‡"
  @unknown_constraint_symbol "*"

  def class_graph_path(conn, data) do
    class_name = data[:name]
    class_type = data[:family]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/" <> class_type <> "/graph/" <> class_name)

      extension ->
        Routes.static_path(conn, "/" <> class_type <> "/graph/" <> extension <> "/" <> class_name)
    end
  end

  def class_path(conn, data) do
    class_name = data[:name]
    class_type = data[:family] <> "s"

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/" <> class_type <> "/" <> class_name)

      extension ->
        Routes.static_path(conn, "/" <> class_type <> "/" <> extension <> "/" <> class_name)
    end
  end

  def object_graph_path(conn, data) do
    object_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/object/graph/" <> object_name)

      extension ->
        Routes.static_path(conn, "/object/graph/" <> extension <> "/" <> object_name)
    end
  end

  def object_path(conn, data) do
    object_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/objects/" <> object_name)

      extension ->
        Routes.static_path(conn, "/objects/" <> extension <> "/" <> object_name)
    end
  end

  def class_profiles(conn, class, profiles) do
    case class[:profiles] || [] do
      [] ->
        ""

      list ->
        [
          "<h5 class='mt-3'>Profiles</h5>",
          "Applicable profiles: ",
          Stream.filter(list, fn profile -> Map.has_key?(profiles, profile) end)
          |> Enum.map_join(", ", fn name ->
            profile_link(conn, get_in(profiles, [name, :caption]), name)
          end),
          "."
        ]
    end
  end

  def profile_badges(conn, class, profiles) do
    case class[:profiles] || [] do
      [] ->
        ""

      list ->
        applicable_profiles =
          Stream.filter(list, fn profile -> Map.has_key?(profiles, profile) end)

        if Enum.empty?(applicable_profiles) do
          ""
        else
          badges =
            Enum.map(applicable_profiles, fn name ->
              caption = get_in(profiles, [name, :caption]) || name
              path = Routes.static_path(conn, "/profiles/" <> name)

              [
                "<span class='profile-badge'>",
                "<a href='",
                path,
                "' title='Profile: ",
                caption,
                "'>",
                "<i class='fas fa-tag'></i> ",
                caption,
                "</a>",
                "</span>"
              ]
            end)

          [
            "<div class='profile-badges'><span class='profile-label'>Applicable Profiles:</span> ",
            Enum.intersperse(badges, " "),
            "</div>"
          ]
        end
    end
  end

  @spec get_applicable_profiles(map(), map()) :: list()
  def get_applicable_profiles(data, profiles) do
    case data[:profiles] || [] do
      [] ->
        []

      list ->
        Stream.filter(list, fn profile -> Map.has_key?(profiles, profile) end)
        |> Enum.to_list()
    end
  end

  @spec format_applicable_profiles_json(list()) :: String.t()
  def format_applicable_profiles_json(applicable_profiles) do
    case applicable_profiles do
      [] ->
        "[]"

      profiles ->
        profiles
        |> Enum.map(&"\"#{&1}\"")
        |> Enum.join(",")
        |> (fn str -> "[#{str}]" end).()
    end
  end

  defp profile_link(_conn, nil, name) do
    name
  end

  defp profile_link(conn, caption, name) do
    path = Routes.static_path(conn, "/profiles/" <> name)
    "<a href='#{path}'>#{caption}</a>"
  end

  def format_profiles(nil) do
    ""
  end

  def format_profiles(profiles) do
    ["data-profiles='", Enum.join(profiles, ","), "'"]
  end

  def indent_class(class) do
    digits = Integer.to_string(class[:uid]) |> String.length()

    # Calculate level based on uid length
    level =
      if class[:extension_id] != nil do
        div(digits - 3, 2) - 1
      else
        div(digits - 3, 2)
      end

    "indent-level-#{level}"
  end

  @spec format_linked_class_caption(String.t(), String.t(), map()) :: any()
  def format_linked_class_caption(path, class_name, class) do
    name = format_caption(class_name, class)

    if Map.has_key?(class, :"@deprecated") do
      [
        "<a href=\"",
        path,
        "\">",
        name,
        " <sup class=\"bg-warning\" data-toggle=\"tooltip\" title=\"Deprecated\">D</sup></a>"
      ]
    else
      ["<a href=\"", path, "\">", name, "</a>"]
    end
  end

  @spec format_caption(any, nil | maybe_improper_list | map) :: any
  def format_caption(name, field) do
    name = field[:caption] || name

    name =
      case field[:uid] do
        nil -> name
        uid -> name <> "<span class='uid'> [#{uid}]</span>"
      end

    case field[:extension] do
      nil ->
        name

      extension when extension != "" ->
        name <>
          " <sup class='source-indicator extension-indicator' data-toggle='tooltip' title='From #{extension} extension'><i class='fas fa-layer-group'></i></sup>"

      _ ->
        name
    end
  end

  @spec format_attribute_caption(any, String.t() | atom, nil | maybe_improper_list | map) :: any
  def format_attribute_caption(_conn, entity_key, entity) do
    caption = entity[:caption] || to_string(entity_key)

    # Add subtle source indicators with icons matching the sidebar
    source_indicators = []

    source_indicators =
      case entity[:extension] do
        nil ->
          source_indicators

        extension when extension != "" ->
          [
            "<sup class='source-indicator extension-indicator' data-toggle='tooltip' title='From #{extension} extension'><i class='fas fa-layer-group'></i></sup>"
            | source_indicators
          ]

        _ ->
          source_indicators
      end

    source_indicators =
      case entity[:profile] do
        nil ->
          source_indicators

        profile when profile != "" ->
          [
            "<sup class='source-indicator profile-indicator' data-toggle='tooltip' title='From #{profile} profile'><i class='fas fa-tag'></i></sup>"
            | source_indicators
          ]

        _ ->
          source_indicators
      end

    if Enum.empty?(source_indicators) do
      caption
    else
      [caption, " ", Enum.reverse(source_indicators)]
    end
  end

  @spec format_attribute_name(String.t() | atom()) :: any
  def format_attribute_name(name) do
    Schema.Utils.descope(name)
  end

  @spec format_class_attribute_source(atom(), map(), String.t()) :: String.t()
  def format_class_attribute_source(class_key, field, class_type) do
    all_classes =
      case class_type do
        "skill" -> Schema.all_skills()
        "domain" -> Schema.all_domains()
        "feature" -> Schema.all_features()
      end

    source = get_hierarchy_source(field)
    {ok, path} = build_hierarchy(Schema.Utils.to_uid(class_key), source, all_classes)

    if ok do
      format_hierarchy(path, all_classes, class_type)
    else
      to_string(source)
    end
  end

  @spec format_object_attribute_source(atom(), map()) :: String.t()
  def format_object_attribute_source(object_key, field) do
    all_objects = Schema.all_objects()
    source = get_hierarchy_source(field)
    {ok, path} = build_hierarchy(Schema.Utils.to_uid(object_key), source, all_objects)

    if ok do
      format_hierarchy(path, all_objects, "object")
    else
      to_string(source)
    end
  end

  defp get_hierarchy_source(field) do
    # In the case of an attribute from a patched class or object, we want to display the final
    # compiled type, which is in :_source_patched and in this case :_source contains the name of
    # the pre-patched item.
    field[:_source_patched] || field[:_source]
  end

  # Build a class or object hierarchy path from item_key to target_parent_item_key.
  # Returns {true, path} when a path is found, and {false, []} otherwise.
  @spec build_hierarchy(atom(), atom(), map(), list()) :: {boolean(), list()}
  defp build_hierarchy(
         item_key,
         target_parent_item_key,
         all_items,
         path_result \\ []
       ) do
    cond do
      item_key == nil ->
        {false, []}

      item_key == target_parent_item_key ->
        {true, [item_key | path_result]}

      true ->
        item = all_items[item_key]
        extends = item[:extends]
        extension = item[:extension]
        {parent_item_key, _parent_time} = Schema.Utils.find_parent(all_items, extends, extension)

        build_hierarchy(
          parent_item_key,
          target_parent_item_key,
          all_items,
          [item_key | path_result]
        )
    end
  end

  defp format_hierarchy(path, all_items, kind) do
    Enum.map(
      path,
      fn item_key ->
        item_info = all_items[item_key]

        if item_info[:hidden?] do
          [all_items[item_key][:caption], " (hidden #{kind})"]
        else
          all_items[item_key][:caption]
        end
      end
    )
    |> Enum.intersperse(" ← ")
  end

  @spec format_range([nil | number | Decimal.t(), ...]) :: nonempty_binary
  def format_range([min, max]) do
    format_number(min) <> "-" <> format_number(max)
  end

  @spec format_requirement(nil | map, atom, nil | map) :: binary
  def format_requirement(constraints, attribute_key, attribute) do
    requirement =
      case attribute[:requirement] do
        nil ->
          "Optional"

        req ->
          String.capitalize(req)
      end

    if constraints do
      # field is an atom while constraint attributes are strings, so convert field
      key_str = to_string(attribute_key)

      [
        requirement,
        Enum.reduce(constraints, [], fn {constraint_type, constraint_attributes}, acc ->
          if Enum.member?(constraint_attributes, key_str) do
            constraint_type_str = to_string(constraint_type)

            {marker, tip} =
              case constraint_type do
                :at_least_one ->
                  {@at_least_one_symbol, "Part of an &quot;at least one&quot; constraint"}

                :just_one ->
                  {@just_one_symbol, "Part of a &quot;just one&quot; constraint"}

                _ ->
                  {@unknown_constraint_symbol,
                   "Part of a &quot;#{constraint_type_str}&quot; constraint"}
              end

            [
              " <a href=\"#",
              constraint_type_str,
              "\" title=\"",
              tip,
              "\">(",
              marker,
              ")</a>"
              | acc
            ]
          else
            acc
          end
        end)
      ]
    else
      requirement
    end
  end

  @spec field_classes(map) :: nonempty_binary
  def field_classes(field) do
    css_classes =
      if field[:_source] == :base_class or field[:_source] == :class do
        "base-class "
      else
        "class "
      end

    css_classes =
      if required?(field) do
        css_classes <> "required "
      else
        if recommended?(field) do
          css_classes <> "recommended "
        else
          css_classes <> "optional "
        end
      end

    group = field[:group]

    css_classes =
      if group != nil do
        css_classes <> group
      else
        css_classes <> "no-group"
      end

    profile = field[:profile]

    css_classes =
      if profile != nil do
        css_classes <> " " <> String.replace(profile, "/", "-")
      else
        css_classes <> " no-profile"
      end

    show_deprecated_css_classes(field, css_classes)
  end

  defp required?(field) do
    r = Map.get(field, :requirement)
    r == "required"
  end

  defp recommended?(field) do
    r = Map.get(field, :requirement)
    r == "recommended"
  end

  def format_constraints(:string_t, field) do
    format_string_constraints(field)
  end

  def format_constraints(:integer_t, field) do
    format_integer_constraints(field)
  end

  def format_constraints(:long_t, field) do
    format_integer_constraints(field)
  end

  def format_constraints("string_t", field) do
    format_string_constraints(field)
  end

  def format_constraints("integer_t", field) do
    format_integer_constraints(field)
  end

  def format_constraints("long_t", field) do
    format_integer_constraints(field)
  end

  def format_constraints(:boolean_t, field) do
    case Map.get(field, :values) do
      nil -> ""
      values -> format_values(values)
    end
  end

  def format_constraints(nil, field) do
    format_max_len(field)
  end

  # format data type constraints: values, range, regex, and max_len
  def format_constraints(_type, field) do
    format_constraints(Map.get(field, :type), field)
  end

  defp format_integer_constraints(field) do
    case Map.get(field, :range) do
      nil ->
        format_values(Map.get(field, :values))

      r ->
        format_range(r)
    end
  end

  defp format_string_constraints(field) do
    max_len = format_max_len(field)

    case Map.get(field, :regex) do
      nil ->
        if max_len == "" do
          format_values(Map.get(field, :values))
        else
          max_len
        end

      r ->
        safe_r = r |> html_escape() |> safe_to_string()

        if max_len == "" do
          safe_r
        else
          max_len <> "<br>" <> safe_r
        end
    end
  end

  defp format_values(nil) do
    ""
  end

  defp format_values(values) do
    Enum.join(values, ", ")
  end

  defp format_max_len(field) do
    case Map.get(field, :max_len) do
      nil -> ""
      max -> "Max length: " <> format_number(max)
    end
  end

  def format_type(conn, field) when is_map(field) do
    type_str =
      case Map.get(field, :type) do
        "object_t" ->
          obj = Map.get(field, :object_type)
          obj_path = SchemaWeb.Router.Helpers.static_path(conn, "/objects/#{obj}")

          case Map.get(field, :object_name) do
            nil ->
              "<a href='#{obj_path}'>#{format_type(conn, obj)}</a>"

            obj_name ->
              format_path(obj_name, obj_path)
          end

        "class_t" ->
          family = Map.get(field, :family)
          class_path = SchemaWeb.Router.Helpers.static_path(conn, "/#{family}s")

          case Map.get(field, :caption) do
            nil ->
              "<a href='#{class_path}'>#{format_type(conn, family)}</a>"

            class_caption ->
              format_path(class_caption, class_path)
          end

        _type ->
          Map.get(field, :type_name) || Map.get(field, :name) || ""
      end

    array? = Map.get(field, :is_array)

    if array? do
      type_str <> " Array"
    else
      type_str
    end
  end

  defp format_path(name, path) do
    if String.starts_with?(name, "*") do
      "<div class='text-danger'>#{name}</div>"
    else
      "<a href='#{path}'>#{name}</a>"
    end
  end

  @spec format_attribute_desc(any, String.t() | atom(), map()) :: any
  def format_attribute_desc(conn, attribute_key, attribute) do
    append_source_references(
      conn,
      base_format_attribute_desc(conn, attribute_key, attribute, false),
      "<p><hr>",
      attribute
    )
  end

  @spec format_dictionary_attribute_desc(any, String.t() | atom(), map()) :: any
  def format_dictionary_attribute_desc(conn, attribute_key, attribute) do
    append_source_references(
      conn,
      base_format_attribute_desc(conn, attribute_key, attribute, true),
      "<p><hr>",
      attribute
    )
  end

  @spec base_format_attribute_desc(any, String.t() | atom(), map(), boolean()) :: any
  defp base_format_attribute_desc(conn, attribute_key, attribute, is_dictionary_view) do
    description = description(attribute)

    cond do
      Map.has_key?(attribute, :enum) or Map.has_key?(attribute, :sibling) ->
        enum_description(conn, description, attribute_key, attribute)

      Map.has_key?(attribute, :_sibling_of) ->
        enum_sibling_description(description, attribute, is_dictionary_view)

      true ->
        description
    end
  end

  defp enum_description(conn, description, attribute_key, attribute) do
    enum_values_table =
      if Map.has_key?(attribute, :enum) do
        enum_values = attribute[:enum]

        sorted =
          if Map.get(attribute, :type) == "integer_t" do
            Enum.sort(
              enum_values,
              fn {k1, _}, {k2, _} ->
                String.to_integer(Atom.to_string(k1)) >= String.to_integer(Atom.to_string(k2))
              end
            )
          else
            Enum.sort(enum_values, fn {k1, _}, {k2, _} -> k1 >= k2 end)
          end

        [
          "<table class=\"mt-1 table-borderless\"><tbody>",
          Enum.reduce(
            sorted,
            [],
            fn {id, item}, acc ->
              id = to_string(id)
              css_classes = show_deprecated_css_classes(item, "bg-transparent")

              [
                "<tr class=\"",
                css_classes,
                "\"><td class=\"text-right\" id=\"",
                to_string(attribute_key),
                "-",
                id,
                "\"><code>",
                id,
                "</code></td><td class=\"textnowrap\">",
                Map.get(item, :caption, id),
                "<div class=\"text-secondary\">",
                append_source_references(conn, description(item), item),
                "</div></td><tr>" | acc
              ]
            end
          ),
          "</tbody></table>"
        ]
      else
        ""
      end

    [
      description,
      enum_values_table,
      if Map.has_key?(attribute, :sibling) do
        [
          "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is an enum attribute; its string sibling is <code>",
          to_string(attribute[:sibling]),
          "</code>.</small></div>"
        ]
      else
        [
          "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is an enum attribute. </small></div>"
        ]
      end
    ]
  end

  defp enum_sibling_description(description, attribute, is_dictionary_view) do
    if is_dictionary_view do
      [
        description,
        "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is the string sibling of enum attribute <code>",
        to_string(attribute[:_sibling_of]),
        "</code> but can also be used independently. See specific usage.</small></div>"
      ]
    else
      [
        description,
        "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is the string sibling of enum attribute <code>",
        to_string(attribute[:_sibling_of]),
        "</code>.</small></div>"
      ]
    end
  end

  @spec append_source_references(any(), any(), map()) :: any()
  defp append_source_references(conn, html, obj) do
    append_source_references(conn, html, "", obj)
  end

  @spec append_source_references(any(), any(), map()) :: any()
  defp append_source_references(conn, html, prefix_html, obj) do
    source = obj[:source]
    references = obj[:references]
    enum = obj[:is_enum]

    source_html =
      if source != nil do
        # source can have embedded markup
        ["<dt>Source<dd class=\"ml-3\">", source]
      else
        ""
      end

    refs_html = inline_references(references)

    options_html =
      if enum do
        case obj[:type] do
          "object_t" ->
            children =
              Schema.Utils.find_children(Schema.all_objects(), obj[:object_type])
              |> Enum.reject(fn item -> item[:hidden?] == true end)

            if children != nil and !Enum.empty?(children) do
              [
                "<dt>Options<dd class=\"ml-3\">",
                Enum.map(children, fn child ->
                  path = Routes.static_path(conn, "/objects/" <> child[:name])

                  [
                    "<div>",
                    "<a href='#{path}'>",
                    child[:caption]
                    |> Phoenix.HTML.html_escape()
                    |> Phoenix.HTML.safe_to_string(),
                    "</a>",
                    "</div>"
                  ]
                end),
                "</dd>",
                "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is an enum attribute. </small></div>"
              ]
            else
              ""
            end

          "class_t" ->
            [
              "<div class=\"mt-2 text-secondary\"><small><i class=\"fas fa-info-circle\"></i> This is an enum attribute. </small></div>"
            ]

          _ ->
            ""
        end
      else
        ""
      end

    if source_html != "" or refs_html != "" or options_html != "" do
      [html, prefix_html, "<dd>", source_html, refs_html, options_html, "</dd>"]
    else
      html
    end
  end

  def constraints(rules) do
    Enum.reduce(rules, [], fn {name, list}, acc ->
      constraints(name, list, acc)
    end)
  end

  def constraints(_name, nil, acc) do
    acc
  end

  def constraints(_name, [], acc) do
    acc
  end

  def constraints(:at_least_one, list, acc) do
    [
      "<span id=\"at_least_one\">",
      @at_least_one_symbol,
      " At least one of these attributes must be present: <strong>",
      Enum.sort(list) |> Enum.join(", "),
      "</strong></span><br>" | acc
    ]
  end

  def constraints(:just_one, list, acc) do
    [
      "<span id=\"just_one\">",
      @just_one_symbol,
      " Just one of these mutually exclusive attributes must be present: <strong>",
      Enum.sort(list) |> Enum.join(", "),
      "</strong></span><br>" | acc
    ]
  end

  def constraints(name, list, acc) do
    [
      "<span id=\"#{name}\">",
      @unknown_constraint_symbol,
      " ",
      to_string(name),
      ": <strong>",
      Enum.sort(list) |> Enum.join(", "),
      "</strong></span><br>" | acc
    ]
  end

  def associations(rules) do
    Enum.reduce(rules, [], fn {name, list}, acc ->
      associations(name, list, acc)
    end)
  end

  def associations(name, list, acc) do
    [Atom.to_string(name), ": ", Enum.join(list, ", "), "<br>" | acc]
  end

  defp reverse_sort_links(links) do
    Enum.sort(
      links,
      fn link1, link2 ->
        link1[:group] >= link2[:group] and link1[:caption] >= link2[:caption]
      end
    )
  end

  defp to_css_selector(value) do
    String.replace(to_string(value), "/", "-")
  end

  defp collapse_html(collapse_id, text, items) do
    [
      "<a class=\"dropdown-toggle\" data-toggle=\"collapse\" data-target=\"#",
      collapse_id,
      "\" aria-expanded=\"false\" aria-controls=\"",
      collapse_id,
      "\">",
      text,
      "</a><br>",
      "<div class=\"collapse multi-collapse\" id=\"",
      collapse_id,
      "\">",
      items,
      "</div>"
    ]
  end

  @spec dictionary_links(any(), String.t(), list(Schema.Utils.link_t())) :: <<>> | list()
  def dictionary_links(_, _, nil), do: ""
  def dictionary_links(_, _, []), do: ""

  def dictionary_links(conn, attribute_name, links) do
    groups = Enum.group_by(links, fn link -> link[:group] end)

    classes_html =
      [
        dictionary_links_class_to_html(conn, attribute_name, groups[:skill], "skill"),
        dictionary_links_class_to_html(conn, attribute_name, groups[:domain], "domain"),
        dictionary_links_class_to_html(conn, attribute_name, groups[:feature], "feature")
      ]
      |> Enum.reject(&Enum.empty?/1)

    objects_html = links_object_to_html(conn, attribute_name, groups[:object], :collapse)

    Enum.reject([classes_html, objects_html], &Enum.empty?/1)
    |> Enum.intersperse("<hr>")
  end

  defp link_css_classes(link) do
    if link[:deprecated?] == true do
      "reference m-0 collapse deprecated"
    else
      "reference m-0"
    end
  end

  defp link_deprecated(link) do
    if link[:deprecated?] == true do
      " <sup class=\"bg-warning\" data-toggle=\"tooltip\" title=\"Deprecated\">D</sup>"
    else
      ""
    end
  end

  defp dictionary_links_class_to_html(_, _, nil, _), do: []

  @spec dictionary_links_class_to_html(any, String.t(), list(Schema.Utils.link_t()), String.t()) ::
          <<>> | list()
  defp dictionary_links_class_to_html(conn, attribute_name, linked_classes, family) do
    {classes, all_classes} =
      case family do
        "skill" ->
          {SchemaController.skills(conn.params), Schema.all_skills()}

        "domain" ->
          {SchemaController.domains(conn.params), Schema.all_domains()}

        "feature" ->
          {SchemaController.features(conn.params), Schema.all_features()}

        _ ->
          Logger.error("Unexpected family value: #{inspect(family)}")
          {Map.new(), Map.new()}
      end

    attribute_key = Schema.Utils.descope_to_uid(attribute_name)

    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path =
            SchemaWeb.Router.Helpers.static_path(conn, "/#{family}s/" <> link[:type])

          class_key = Schema.Utils.to_uid(link[:type])

          attribute =
            case Map.get(classes[class_key][:attributes], attribute_key) do
              nil ->
                Enum.find_value(classes[class_key][:attributes], fn {_key, attr} ->
                  if attr[:reference] == Atom.to_string(attribute_key), do: attr, else: nil
                end)

              attr ->
                attr
            end

          source = attribute[:_source_patched] || attribute[:_source]

          cond do
            source == nil ->
              # This means the attribute's :_source is incorrectly missing. Show with warning.
              [
                [
                  "<div class=\"",
                  link_css_classes(link),
                  "\"><a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"No source\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link),
                  " <span class=\"bg-warning\">No source</span></div>"
                ]
                | acc
              ]

            source == class_key ->
              [
                [
                  "<div class=\"",
                  link_css_classes(link),
                  "\"><a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"Directly referenced\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link),
                  "</div>"
                ]
                | acc
              ]

            true ->
              # Any indirect situation, including through hidden classes
              {ok, path} = build_hierarchy(class_key, source, all_classes)

              if ok do
                [
                  [
                    "<div class=\"",
                    link_css_classes(link),
                    "\"><a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Indirectly referenced: ",
                    format_hierarchy(path, all_classes, "class"),
                    "\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link),
                    "</div>"
                  ]
                  | acc
                ]
              else
                # This means there's a bad class hierarchy. Show with warning.
                [
                  [
                    "<div class=\"",
                    link_css_classes(link),
                    "\"><a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Referenced via unknown parent\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link),
                    " <span class=\"bg-warning\">Unknown parent</span></div>"
                  ]
                  | acc
                ]
              end
          end
        end
      )

    if Enum.empty?(html_list) do
      []
    else
      noun_text = if length(html_list) == 1, do: " #{family}", else: " #{family}s"

      deprecated_count =
        Enum.reduce(linked_classes, 0, fn link, acc ->
          if link[:deprecated?], do: acc + 1, else: acc
        end)

      deprecated_text =
        if deprecated_count > 0 do
          [" (", to_string(deprecated_count), " deprecated)"]
        else
          ""
        end

      collapse_html(
        ["#{family}-links-", to_css_selector(attribute_name)],
        ["Referenced by ", Integer.to_string(length(html_list)), noun_text, deprecated_text],
        html_list
      )
    end
  end

  # Used by dictionary_links and profile_links
  defp links_object_to_html(_, _, nil, _), do: []

  defp links_object_to_html(conn, name, linked_objects, list_presentation) do
    html_list =
      reverse_sort_links(linked_objects)
      |> Enum.reduce(
        [],
        fn link, acc ->
          [
            [
              "<div class=\"",
              link_css_classes(link),
              "\"><a href=\"",
              SchemaWeb.Router.Helpers.static_path(conn, "/objects/" <> link[:type]),
              "\">",
              link[:caption],
              " Object</a>",
              link_deprecated(link),
              "</div>"
            ]
            | acc
          ]
        end
      )

    cond do
      Enum.empty?(html_list) ->
        []

      list_presentation == :collapse ->
        noun_text = if length(html_list) == 1, do: " object", else: " objects"

        deprecated_count =
          Enum.reduce(linked_objects, 0, fn link, acc ->
            if link[:deprecated?], do: acc + 1, else: acc
          end)

        deprecated_text =
          if deprecated_count > 0 do
            [" (", to_string(deprecated_count), " deprecated)"]
          else
            ""
          end

        collapse_html(
          ["object-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text, deprecated_text],
          html_list
        )

      true ->
        html_list
    end
  end

  @spec object_links(any(), String.t(), list(Schema.Utils.link_t()), nil | :collapse) ::
          <<>> | list()
  def object_links(conn, name, links, list_presentation \\ nil)
  def object_links(_, _, nil, _), do: ""
  def object_links(_, _, [], _), do: ""

  def object_links(conn, name, links, list_presentation) do
    groups = Enum.group_by(links, fn link -> link[:group] end)

    classes_html =
      [
        object_links_class_to_html(conn, name, groups[:skill], list_presentation, "skill"),
        object_links_class_to_html(conn, name, groups[:domain], list_presentation, "domain"),
        object_links_class_to_html(conn, name, groups[:feature], list_presentation, "feature")
      ]
      |> Enum.reject(&Enum.empty?/1)

    objects_html = object_links_object_to_html(conn, name, groups[:object], list_presentation)

    Enum.reject([classes_html, objects_html], &Enum.empty?/1)
    |> Enum.intersperse("<hr>")
  end

  defp link_attributes(link) do
    attribute_keys = link[:attribute_keys]
    attribute_keys_size = if attribute_keys == nil, do: 0, else: MapSet.size(attribute_keys)

    case attribute_keys_size do
      0 ->
        "No attributes"

      1 ->
        ["Attribute: ", to_string(Enum.at(attribute_keys, 0))]

      _ ->
        ["Attributes: ", Enum.intersperse(Enum.map(attribute_keys, &to_string/1), ", ")]
    end
  end

  defp object_links_class_to_html(_, _, nil, _, _), do: []

  defp object_links_class_to_html(conn, name, linked_classes, list_presentation, family) do
    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path = SchemaWeb.Router.Helpers.static_path(conn, "/#{family}s/" <> link[:type])

          [
            if list_presentation == :collapse do
              [
                "<div class=\"",
                link_css_classes(link),
                "\"><a href=\"",
                type_path,
                "\" data-toggle=\"tooltip\" title=\"",
                link_attributes(link),
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link),
                "</div>"
              ]
            else
              [
                "<div class=\"",
                link_css_classes(link),
                "\"><dt><a href=\"",
                type_path,
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link),
                "<dd class=\"ml-3\">",
                link_attributes(link),
                "</div>"
              ]
            end
            | acc
          ]
        end
      )

    cond do
      Enum.empty?(html_list) ->
        []

      list_presentation == :collapse ->
        noun_text = if length(html_list) == 1, do: " #{family}", else: " #{family}s"

        deprecated_count =
          Enum.reduce(linked_classes, 0, fn link, acc ->
            if link[:deprecated?], do: acc + 1, else: acc
          end)

        deprecated_text =
          if deprecated_count > 0 do
            [" (", to_string(deprecated_count), " deprecated)"]
          else
            ""
          end

        collapse_html(
          ["#{family}-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text, deprecated_text],
          html_list
        )

      true ->
        ["<dl class=\"m-0\">", html_list, "</dl>"]
    end
  end

  defp object_links_object_to_html(_, _, nil, _), do: []

  defp object_links_object_to_html(conn, name, linked_objects, list_presentation) do
    html_list =
      reverse_sort_links(linked_objects)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path = SchemaWeb.Router.Helpers.static_path(conn, "/objects/" <> link[:type])

          [
            if list_presentation == :collapse do
              [
                "<div class=\"",
                link_css_classes(link),
                "\"><a href=\"",
                type_path,
                "\" data-toggle=\"tooltip\" title=\"",
                link_attributes(link),
                "\">",
                link[:caption],
                " Object</a>",
                link_deprecated(link),
                "</div>"
              ]
            else
              [
                "<div class=\"",
                link_css_classes(link),
                "\"><dt><a href=\"",
                type_path,
                "\">",
                link[:caption],
                " Object</a>",
                link_deprecated(link),
                "<dd class=\"ml-3\">",
                link_attributes(link),
                "</div>"
              ]
            end
            | acc
          ]
        end
      )

    cond do
      Enum.empty?(html_list) ->
        []

      list_presentation == :collapse ->
        noun_text = if length(html_list) == 1, do: " object", else: " objects"

        deprecated_count =
          Enum.reduce(linked_objects, 0, fn link, acc ->
            if link[:deprecated?], do: acc + 1, else: acc
          end)

        deprecated_text =
          if deprecated_count > 0 do
            [" (", to_string(deprecated_count), " deprecated)"]
          else
            ""
          end

        collapse_html(
          ["object-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text, deprecated_text],
          html_list
        )

      true ->
        ["<dl class=\"m-0\">", html_list, "</dl>"]
    end
  end

  @spec profile_links(any(), String.t(), list(Schema.Utils.link_t()), nil | :collapse) ::
          <<>> | list()
  def profile_links(conn, profile_name, links, list_presentation \\ nil)
  def profile_links(_, _, nil, _), do: ""
  def profile_links(_, _, [], _), do: ""

  def profile_links(conn, profile_name, links, list_presentation) do
    groups = Enum.group_by(links, fn link -> link[:group] end)

    classes_html =
      [
        profile_links_class_to_html(
          conn,
          profile_name,
          groups[:skill],
          list_presentation,
          "skill"
        ),
        profile_links_class_to_html(
          conn,
          profile_name,
          groups[:domain],
          list_presentation,
          "domain"
        ),
        profile_links_class_to_html(
          conn,
          profile_name,
          groups[:feature],
          list_presentation,
          "feature"
        )
      ]
      |> Enum.reject(&Enum.empty?/1)

    objects_html = links_object_to_html(conn, profile_name, groups[:object], list_presentation)

    Enum.reject([classes_html, objects_html], &Enum.empty?/1)
    |> Enum.intersperse("<hr>")
  end

  defp profile_links_class_to_html(_, _, nil, _, _), do: []

  defp profile_links_class_to_html(conn, profile_name, linked_classes, list_presentation, family) do
    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          [
            [
              "<div class=\"",
              link_css_classes(link),
              "\"><a href=\"",
              SchemaWeb.Router.Helpers.static_path(conn, "/#{family}s/" <> link[:type]),
              "\">",
              link[:caption],
              " Class</a>",
              link_deprecated(link),
              "</div>"
            ]
            | acc
          ]
        end
      )

    cond do
      Enum.empty?(html_list) ->
        []

      list_presentation == :collapse ->
        noun_text = if length(html_list) == 1, do: " #{family}", else: " #{family}s"

        deprecated_count =
          Enum.reduce(linked_classes, 0, fn link, acc ->
            if link[:deprecated?], do: acc + 1, else: acc
          end)

        deprecated_text =
          if deprecated_count > 0 do
            [" (", to_string(deprecated_count), " deprecated)"]
          else
            ""
          end

        collapse_html(
          ["#{family}-links-", to_css_selector(profile_name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text, deprecated_text],
          html_list
        )

      true ->
        html_list
    end
  end

  defp format_number(n) do
    Number.Delimit.number_to_delimited(n, precision: 0)
  end

  def description(map) do
    deprecated(map, Map.get(map, :"@deprecated"))
  end

  defp deprecated(map, nil) do
    Map.get(map, :description) || ""
  end

  defp deprecated(map, deprecated) do
    [
      Map.get(map, :description) || "",
      "<div class='text-dark mt-2'><span class='bg-warning'>DEPRECATED since v",
      Map.get(deprecated, :since),
      "</span></div>",
      Map.get(deprecated, :message)
    ]
  end

  @spec reference_anchor(map()) :: any()
  def reference_anchor(reference) do
    # The url and description attributes of reference are not meant to have markup
    [
      "<a target=\"_blank\" href=\"",
      URI.encode(reference[:url]),
      "\">",
      reference[:description] |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string(),
      "</a>"
    ]
  end

  @spec reference_tag(map()) :: any()
  def reference_tag(reference) do
    # New compact reference tag styling
    [
      "<a class=\"reference-tag\" target=\"_blank\" href=\"",
      URI.encode(reference[:url]),
      "\">",
      reference[:description] |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string(),
      "</a>"
    ]
  end

  @spec object_references_section(list()) :: any()
  def object_references_section(references) when is_list(references) and length(references) > 0 do
    [
      "<div class=\"object-references\">",
      "<h6>References</h6>",
      "<ul class=\"references-list\">",
      Enum.map(references, fn ref -> ["<li>", reference_tag(ref), "</li>"] end),
      "</ul>",
      "</div>"
    ]
  end

  def object_references_section(_), do: ""

  @spec inline_references(list()) :: any()
  def inline_references(references) when is_list(references) and length(references) > 0 do
    [
      "<div class=\"references-inline\">",
      "<span class=\"references-label\">Refs:</span>",
      Enum.intersperse(Enum.map(references, &reference_tag/1), " "),
      "</div>"
    ]
  end

  def inline_references(_), do: ""

  @spec show_deprecated_css_classes(map(), String.t()) :: String.t()
  def show_deprecated_css_classes(item, initial) do
    if item[:"@deprecated"] != nil do
      initial <> " collapse deprecated"
    else
      initial
    end
  end

  @spec show_deprecated_css_classes(map()) :: String.t()
  def show_deprecated_css_classes(item) do
    show_deprecated_css_classes(item, "")
  end
end
