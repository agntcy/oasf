defmodule SchemaWeb.PageView do
  alias SchemaWeb.SchemaController
  use SchemaWeb, :view

  @at_least_one_symbol "†"
  @just_one_symbol "‡"
  @unknown_constraint_symbol "*"

  def class_graph_path(conn, data) do
    class_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/class/graph/" <> class_name)

      extension ->
        Routes.static_path(conn, "/class/graph/" <> extension <> "/" <> class_name)
    end
  end

  def class_path(conn, data) do
    class_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/classes/" <> class_name)

      extension ->
        Routes.static_path(conn, "/classes/" <> extension <> "/" <> class_name)
    end
  end

  def domain_graph_path(conn, data) do
    domain_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/domain/graph/" <> domain_name)

      extension ->
        Routes.static_path(conn, "/domain/graph/" <> extension <> "/" <> domain_name)
    end
  end

  def domain_path(conn, data) do
    domain_name = data[:name]

    case data[:extension] do
      nil ->
        Routes.static_path(conn, "/domains/" <> domain_name)

      extension ->
        Routes.static_path(conn, "/domains/" <> extension <> "/" <> domain_name)
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

  def domain_profiles(conn, domain, profiles) do
    case domain[:profiles] || [] do
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
      nil -> name
      extension -> name <> " <sup>#{extension}</sup>"
    end
  end

  @spec format_attribute_caption(any, String.t() | atom, nil | maybe_improper_list | map) :: any
  def format_attribute_caption(conn, entity_key, entity) do
    {observable_type_id, observable_kind} = observable_type_id_and_kind(entity)

    caption = entity[:caption] || to_string(entity_key)

    caption =
      case observable_type_id do
        nil ->
          caption

        type_id ->
          type_id = to_string(type_id)

          [
            caption,
            " <sup><a href=\"",
            SchemaWeb.Router.Helpers.static_path(conn, "/objects/observable"),
            "#type_id-",
            type_id,
            "\" data-toggle=\"tooltip\" title=\"Observable Type ID ",
            type_id,
            ": ",
            observable_kind,
            "\">O</a></sup>"
          ]
      end

    case entity[:extension] do
      nil -> caption
      extension -> [caption, " <sup>#{extension}</sup>"]
    end
  end

  defp observable_type_id_and_kind(entity) do
    observable_object = Schema.object(:observable)

    observable_type_id_map =
      if observable_object do
        observable_object[:attributes][:type_id][:enum]
      else
        nil
      end

    cond do
      observable_type_id_map == nil ->
        {nil, nil}

      Map.has_key?(entity, :observable) ->
        observable_type_id = Schema.Utils.observable_type_id_to_atom(entity[:observable])
        enum_details = observable_type_id_map[observable_type_id]

        {
          observable_type_id,
          "#{enum_details[:caption]} (#{enum_details[:_observable_kind]})"
        }

      Map.has_key?(entity, :type) ->
        # Check if this is a dictionary type
        type = Schema.dictionary()[:types][:attributes][Schema.Utils.to_uid(entity[:type])]
        type_observable = type[:observable]

        cond do
          type_observable ->
            observable_type_id = Schema.Utils.observable_type_id_to_atom(type_observable)
            enum_details = observable_type_id_map[observable_type_id]

            {
              observable_type_id,
              "#{enum_details[:caption]} (#{enum_details[:_observable_kind]})"
            }

          Map.has_key?(entity, :object_type) ->
            # Check if this object is an observable
            object_key = Schema.Utils.to_uid(entity[:object_type])
            object_observable = Schema.object(object_key)[:observable]

            if object_observable do
              observable_type_id = Schema.Utils.observable_type_id_to_atom(object_observable)
              enum_details = observable_type_id_map[observable_type_id]

              {
                observable_type_id,
                "#{enum_details[:caption]} (#{enum_details[:_observable_kind]})"
              }
            else
              {nil, nil}
            end

          true ->
            {nil, nil}
        end

      true ->
        {nil, nil}
    end
  end

  @spec format_attribute_name(String.t() | atom()) :: any
  def format_attribute_name(name) do
    Path.basename(to_string(name))
  end

  @spec format_class_attribute_source(atom(), map()) :: String.t()
  def format_class_attribute_source(class_key, field) do
    all_classes = Schema.all_classes()
    source = get_hierarchy_source(field)
    {ok, path} = build_hierarchy(Schema.Utils.to_uid(class_key), source, all_classes)

    if ok do
      format_hierarchy(path, all_classes, "class")
    else
      to_string(source)
    end
  end

  @spec format_domain_attribute_source(atom(), map()) :: String.t()
  def format_domain_attribute_source(domain_key, field) do
    all_domains = Schema.all_domains()
    source = get_hierarchy_source(field)
    {ok, path} = build_hierarchy(Schema.Utils.to_uid(domain_key), source, all_domains)

    if ok do
      format_hierarchy(path, all_domains, "domain")
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
    base =
      if field[:_source] == :base_class or field[:_source] == :event do
        "base-event "
      else
        "event "
      end

    deprecation_status =
      if field[:"@deprecated"] != nil do
        base <> "deprecated "
      else
        base <> "not-deprecated "
      end

    classes =
      if required?(field) do
        deprecation_status <> "required "
      else
        if recommended?(field) do
          deprecation_status <> "recommended "
        else
          deprecation_status <> "optional "
        end
      end

    group = field[:group]

    classes =
      if group != nil do
        classes <> group
      else
        classes <> "no-group"
      end

    profile = field[:profile]

    if profile != nil do
      classes <> " " <> String.replace(profile, "/", "-")
    else
      classes <> " no-profile"
    end
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
        case max_len do
          "" ->
            format_values(Map.get(field, :values))

          len ->
            len
        end

      r ->
        max_len <> "<br>" <> r
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
              format_object_path(obj_name, obj_path)
          end

        _type ->
          Map.get(field, :type_name) || ""
      end

    array? = Map.get(field, :is_array)

    if array? do
      type_str <> " Array"
    else
      type_str
    end
  end

  defp format_object_path(name, path) do
    if String.starts_with?(name, "*") do
      "<div class='text-danger'>#{name}</div>"
    else
      "<a href='#{path}'>#{name}</a>"
    end
  end

  @spec format_desc(String.t() | atom(), map()) :: any
  def format_desc(key, obj) do
    append_source_references(base_format_desc(key, obj), "<p><hr>", obj)
  end

  @spec base_format_desc(String.t() | atom(), map()) :: any
  defp base_format_desc(key, obj) do
    description = description(obj)

    case Map.get(obj, :enum) do
      nil ->
        [description]

      values ->
        sorted =
          if Map.get(obj, :type) == "integer_t" do
            Enum.sort(
              values,
              fn {k1, _}, {k2, _} ->
                String.to_integer(Atom.to_string(k1)) >= String.to_integer(Atom.to_string(k2))
              end
            )
          else
            Enum.sort(values, fn {k1, _}, {k2, _} -> k1 >= k2 end)
          end

        [
          description,
          """
          <table class="mt-1 table-borderless"><tbody>
          """,
          Enum.reduce(
            sorted,
            [],
            fn {id, item}, acc ->
              id = to_string(id)

              [
                "<tr class='bg-transparent'><td style='width: 25px' class='text-right' id='",
                to_string(key),
                "-",
                id,
                "'><code>",
                id,
                "</code></td><td class='textnowrap'>",
                Map.get(item, :caption, id),
                "<div class='text-secondary'>",
                append_source_references(description(item), item),
                "</div></td><tr>" | acc
              ]
            end
          ),
          "</tbody></table>"
        ]
    end
  end

  @spec append_source_references(any(), map()) :: any()
  defp append_source_references(html, obj) do
    append_source_references(html, "", obj)
  end

  @spec append_source_references(any(), any(), map()) :: any()
  defp append_source_references(html, prefix_html, obj) do
    source = obj[:source]
    references = obj[:references]

    source_html =
      if source != nil do
        # source can have embedded markup
        ["<dt>Source<dd class=\"ml-3\">", source]
      else
        ""
      end

    refs_html =
      if references != nil and !Enum.empty?(references) do
        [
          "<dt>References",
          Enum.map(references, fn ref -> ["<dd class=\"ml-3\">", reference_anchor(ref)] end)
        ]
      else
        ""
      end

    if source_html != "" or refs_html != "" do
      [html, prefix_html, "<dd>", source_html, refs_html, "</dd>"]
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

    commons_html = dictionary_links_common_to_html(conn, groups[:common])

    classes_html =
      if Enum.empty?(commons_html) do
        dictionary_links_class_to_html(conn, attribute_name, groups[:class])
      else
        Enum.intersperse(
          [
            "Referenced by all classes",
            dictionary_links_class_updated_to_html(conn, attribute_name, groups[:class])
          ],
          "<br>"
        )
      end

    objects_html = links_object_to_html(conn, attribute_name, groups[:object], :collapse)

    Enum.reject([commons_html, classes_html, objects_html], &Enum.empty?/1)
    |> Enum.intersperse("<hr>")
  end

  defp dictionary_links_common_to_html(_, nil), do: []

  defp dictionary_links_common_to_html(conn, linked_classes) do
    reverse_sort_links(linked_classes)
    |> Enum.reduce(
      [],
      fn _link, acc ->
        [
          [
            "<a href=\"",
            SchemaWeb.Router.Helpers.static_path(conn, "/classes/base_class"),
            "\" data-toggle=\"tooltip\ title=\"Directly referenced\">Base Event Class</a>"
          ]
          | acc
        ]
      end
    )
    |> Enum.intersperse("<br>")
  end

  defp link_deprecated(link) do
    if link[:deprecated?] == true do
      " <sup class=\"bg-warning\" data-toggle=\"tooltip\" title=\"Deprecated\">D</sup>"
    else
      ""
    end
  end

  defp dictionary_links_class_to_html(_, _, nil), do: []

  defp dictionary_links_class_to_html(conn, attribute_name, linked_classes) do
    classes = SchemaController.classes(conn.params)
    all_classes = Schema.all_classes()
    attribute_key = Schema.Utils.descope_to_uid(attribute_name)

    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path = SchemaWeb.Router.Helpers.static_path(conn, "/classes/" <> link[:type])
          class_key = Schema.Utils.to_uid(link[:type])
          attribute = classes[class_key][:attributes][attribute_key]
          source = attribute[:_source_patched] || attribute[:_source]

          cond do
            source == nil ->
              # This means the attribute's :_source is incorrectly missing. Show with warning.
              [
                [
                  "<a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"No source\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link),
                  " <span class=\"bg-warning\">No source</span>"
                ]
                | acc
              ]

            source == class_key ->
              [
                [
                  "<a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"Directly referenced\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link)
                ]
                | acc
              ]

            true ->
              # Any indirect situation, including through hidden classes
              {ok, path} = build_hierarchy(class_key, source, all_classes)

              if ok do
                [
                  [
                    "<a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Indirectly referenced: ",
                    format_hierarchy(path, all_classes, "class"),
                    "\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link)
                  ]
                  | acc
                ]
              else
                # This means there's a bad class hierarchy. Show with warning.
                [
                  [
                    "<a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Referenced via unknown parent\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link),
                    " <span class=\"bg-warning\">Unknown parent</span>"
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
      noun_text = if length(html_list) == 1, do: " class", else: " classes"

      collapse_html(
        ["class-links-", to_css_selector(attribute_name)],
        ["Referenced by ", Integer.to_string(length(html_list)), noun_text],
        Enum.intersperse(html_list, "<br>")
      )
    end
  end

  defp dictionary_links_class_updated_to_html(_, _, nil), do: []

  defp dictionary_links_class_updated_to_html(conn, attribute_name, linked_classes) do
    classes = SchemaController.classes(conn.params)
    all_classes = Schema.all_classes()
    attribute_key = Schema.Utils.descope_to_uid(attribute_name)

    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          class_key = Schema.Utils.to_uid(link[:type])

          type_path = SchemaWeb.Router.Helpers.static_path(conn, "/classes/" <> link[:type])
          attribute = classes[class_key][:attributes][attribute_key]
          source = attribute[:_source_patched] || attribute[:_source]

          cond do
            source == nil ->
              # This means the attribute's :_source is incorrectly missing. Show with warning.
              [
                [
                  "<a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"No source\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link),
                  " <span class=\"bg-warning\">No source</span>"
                ]
                | acc
              ]

            source == :base_class ->
              # Skip base_class source:
              #   - Reduces noise
              #   - It is redundant with showing Base Event Class separately
              acc

            source == class_key ->
              [
                [
                  "<a href=\"",
                  type_path,
                  "\" data-toggle=\"tooltip\" title=\"Directly updated\">",
                  link[:caption],
                  " Class</a>",
                  link_deprecated(link)
                ]
                | acc
              ]

            true ->
              # Any indirect situation, including through hidden classes
              {ok, path} = build_hierarchy(class_key, source, all_classes)

              if ok do
                [
                  [
                    "<a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Indirectly updated: ",
                    format_hierarchy(path, all_classes, "class"),
                    "\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link)
                  ]
                  | acc
                ]
              else
                # This means there's a bad class hierarchy. Show with warning.
                [
                  [
                    "<a href=\"",
                    type_path,
                    "\" data-toggle=\"tooltip\" title=\"Updated via unknown parent\">",
                    link[:caption],
                    " Class</a>",
                    link_deprecated(link),
                    " <span class=\"bg-warning\">Unknown parent</span>"
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
      noun_text = if length(html_list) == 1, do: " class", else: " classes"

      collapse_html(
        ["class-links-", to_css_selector(attribute_name)],
        [
          "Updated in ",
          Integer.to_string(length(html_list)),
          noun_text
        ],
        Enum.intersperse(html_list, "<br>")
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
              "<a href=\"",
              SchemaWeb.Router.Helpers.static_path(conn, "/objects/" <> link[:type]),
              "\">",
              link[:caption],
              " Object</a>",
              link_deprecated(link)
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

        collapse_html(
          ["object-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text],
          Enum.intersperse(html_list, "<br>")
        )

      true ->
        Enum.intersperse(html_list, "<br>")
    end
  end

  @spec object_links(any(), String.t(), list(Schema.Utils.link_t()), nil | :collapse) ::
          <<>> | list()
  def object_links(conn, name, links, list_presentation \\ nil)
  def object_links(_, _, nil, _), do: ""
  def object_links(_, _, [], _), do: ""

  def object_links(conn, name, links, list_presentation) do
    groups = Enum.group_by(links, fn link -> link[:group] end)

    commons_html = object_links_common_to_html(conn, groups[:common], list_presentation)
    classes_html = object_links_class_to_html(conn, name, groups[:class], list_presentation)
    objects_html = object_links_object_to_html(conn, name, groups[:object], list_presentation)

    Enum.reject([commons_html, classes_html, objects_html], &Enum.empty?/1)
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

  defp object_links_common_to_html(_, nil, _), do: []

  defp object_links_common_to_html(conn, linked_classes, list_presentation) do
    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path =
            if link[:type] == "base_class" do
              SchemaWeb.Router.Helpers.static_path(conn, "/classes/base_class")
            else
              SchemaWeb.Router.Helpers.static_path(conn, "/classes/" <> link[:type])
            end

          [
            if list_presentation == :collapse do
              [
                "<a href=\"",
                type_path,
                "\" data-toggle=\"tooltip\" title=\"",
                link_attributes(link),
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link)
              ]
            else
              [
                "<dt><a href=\"",
                type_path,
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link),
                "<dd class=\"ml-3\">",
                link_attributes(link)
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
        Enum.intersperse(html_list, "<br>")

      true ->
        ["<dl class=\"m-0\">", html_list, "</dl>"]
    end
  end

  defp object_links_class_to_html(_, _, nil, _), do: []

  defp object_links_class_to_html(conn, name, linked_classes, list_presentation) do
    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          type_path = SchemaWeb.Router.Helpers.static_path(conn, "/classes/" <> link[:type])

          [
            if list_presentation == :collapse do
              [
                "<a href=\"",
                type_path,
                "\" data-toggle=\"tooltip\" title=\"",
                link_attributes(link),
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link)
              ]
            else
              [
                "<dt><a href=\"",
                type_path,
                "\">",
                link[:caption],
                " Class</a>",
                link_deprecated(link),
                "<dd class=\"ml-3\">",
                link_attributes(link)
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
        noun_text = if length(html_list) == 1, do: " class", else: " classes"

        collapse_html(
          ["class-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text],
          Enum.intersperse(html_list, "<br>")
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
                "<a href=\"",
                type_path,
                "\" data-toggle=\"tooltip\" title=\"",
                link_attributes(link),
                "\">",
                link[:caption],
                " Object</a>",
                link_deprecated(link)
              ]
            else
              [
                "<dt><a href=\"",
                type_path,
                "\">",
                link[:caption],
                " Object</a>",
                link_deprecated(link),
                "<dd class=\"ml-3\">",
                link_attributes(link)
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

        collapse_html(
          ["object-links-", to_css_selector(name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text],
          Enum.intersperse(html_list, "<br>")
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

    commons_html = profile_links_common_to_html(conn, groups[:common])

    classes_html =
      profile_links_class_to_html(conn, profile_name, groups[:class], list_presentation)

    objects_html = links_object_to_html(conn, profile_name, groups[:object], list_presentation)

    Enum.reject([commons_html, classes_html, objects_html], &Enum.empty?/1)
    |> Enum.intersperse("<hr>")
  end

  defp profile_links_common_to_html(_, nil), do: []

  defp profile_links_common_to_html(conn, linked_classes) do
    reverse_sort_links(linked_classes)
    |> Enum.reduce(
      [],
      fn _link, acc ->
        [
          [
            "<a href=\"",
            SchemaWeb.Router.Helpers.static_path(conn, "/classes/base_class"),
            "\">Base Event Class</a>"
          ]
          | acc
        ]
      end
    )
    |> Enum.intersperse("<br>")
  end

  defp profile_links_class_to_html(_, _, nil, _), do: []

  defp profile_links_class_to_html(conn, profile_name, linked_classes, list_presentation) do
    html_list =
      reverse_sort_links(linked_classes)
      |> Enum.reduce(
        [],
        fn link, acc ->
          [
            [
              "<a href=\"",
              SchemaWeb.Router.Helpers.static_path(conn, "/classes/" <> link[:type]),
              "\">",
              link[:caption],
              " Class</a>",
              link_deprecated(link)
            ]
            | acc
          ]
        end
      )

    cond do
      Enum.empty?(html_list) ->
        []

      list_presentation == :collapse ->
        noun_text = if length(html_list) == 1, do: " class", else: " classes"

        collapse_html(
          ["class-links-", to_css_selector(profile_name)],
          ["Referenced by ", Integer.to_string(length(html_list)), noun_text],
          Enum.intersperse(html_list, "<br>")
        )

      true ->
        Enum.intersperse(html_list, "<br>")
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
end
