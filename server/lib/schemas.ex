defmodule Schemas do
  @moduledoc """
  This module provides function to work with multiple schema versions.
  """

  use Agent

  require Logger

  # The Schema version file
  @version_file "version.json"

  def start_link(nil) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def start_link(path) do
    Agent.start_link(fn -> ls(path) end, name: __MODULE__)
  end

  @doc """
  Returns a list of available schemas.

  Returns {:ok, list(map())}.
  """
  def versions do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Returns a list of schemas is the given directory.

  Returns list of {version, path} tuples in case of success, {:error, reason} otherwise.
  """
  @spec ls(Path.t()) :: list({String.t(), String.t()}) | {:error, File.posix()}
  def ls(path) do
    with {:ok, list} <- File.ls(path) do
      Stream.map(list, fn name ->
        Path.join(path, name)
      end)
      |> Stream.map(fn dir ->
        with {:ok, data} <- File.read(Path.join(dir, @version_file)),
             {:ok, json} <- Jason.decode(data),
             {:ok, version} <- version(json) do
          {:ok, version, dir}
        else
          {:error, reason} when is_atom(reason) ->
            err_msg = :file.format_error(reason)
            Logger.error("No schema version file found in #{dir}. Error: #{err_msg}")
            {:error, err_msg, dir}

          {:error, reason} ->
            Logger.error("Invalid schema version file in #{dir}. Error: #{inspect(reason)}")
            {:error, reason, dir}
        end
      end)
      |> Stream.filter(fn
        {:ok, _, _} -> true
        {_er, _, _} -> false
      end)
      |> Enum.map(fn {_, version, path} -> {version, path} end)
      # Simplistic lexical sort of versions - not perfect, but better than random
      |> Enum.sort(fn {v1, _p1}, {v2, _p2} -> v1 <= v2 end)
    else
      {:error, reason} ->
        err_msg = :file.format_error(reason)
        Logger.error("Invalid schema directory: #{err_msg}")
        {:error, err_msg}
    end
  end

  defp version(data) do
    case data["version"] do
      nil ->
        {:error, "Missing 'version' attribute"}

      version ->
        {:ok, version}
    end
  end
end
