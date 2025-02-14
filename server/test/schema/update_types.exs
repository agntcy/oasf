defmodule Schema.UpdateTypes do
  def update(path) do
    File.read!(path)
    |> Jason.decode!()
    |> Map.update!("attributes", fn attributes ->
      Enum.into(attributes, %{}, fn {name, a} ->
        updated =
          case Map.pop(a, "object_type") do
            {nil, _} ->
              a

            {type, map} ->
              Map.put(map, "type", type)
          end

        {name, updated}
      end)
    end)
  end
end
