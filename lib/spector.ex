defmodule Spector do
  @moduledoc """
  A tiny library for validating and documenting specs.
  """

  alias Spector.ValidationError

  def validate(data, schema) when is_map(data) do
    validate_map(data, transform_schema(schema))
  end

  def validate(data, schema, :yaml) do
    schema =
      schema
      |> YamlElixir.read_from_string!()

    data
    |> YamlElixir.read_from_string!()
    |> validate(schema)
  end

  def validate(data, schema, :json) do
    schema =
      schema
      |> Jason.decode!()

    data
    |> Jason.decode!()
    |> validate(schema)
  end

  defp validate_map(data, schema, acc \\ {:ok, %{}})

  defp validate_map(data, schema, {:ok, acc}) do
    schema
    |> Enum.reduce({:ok, acc}, fn {key, opts}, acc ->
      validate_key(data, key, opts, acc)
    end)
  end

  defp validate_key(data, key, opts, {:ok, acc}) do
    case Map.fetch(data, key) do
      {:ok, value} -> validate_value(data, key, value, opts, acc)
      :error -> handle_missing_key(data, key, opts, acc)
    end
  end

  defp validate_value(_data, key, value, %{"type" => "map", "keys" => sub_schema}, acc)
       when is_map(value) do
    case validate_map(value, sub_schema) do
      {:ok, _} -> {:ok, Map.put(acc, key, value)}
      {:error, _} = error -> error
    end
  end

  defp validate_value(_data, key, value, opts, acc) do
    with true <- validate_required(key, opts),
         true <- validate_type(value, opts["type"], key) do
      {:ok, Map.put(acc, key, value)}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_required(key, opts) do
    case opts do
      %{required: true} ->
        if Map.has_key?(opts, key),
          do: true,
          else: {:error, "#{key} is required but not provided"}

      _ ->
        true
    end
  end

  # defp validate_required(_data, _key, %{"required" => required}) when required in [nil, false],
  #   do: true

  # defp validate_required(data, key, %{"required" => true}) do
  #   if Map.has_key?(data, key) do
  #     true
  #   else
  #     error_tuple(
  #       key,
  #       nil,
  #       "#{key} is required but not provided"
  #     )
  #   end
  # end

  # defp validate_required(_data, _key, _), do: true

  defp validate_type(_value, nil, _key), do: true

  defp validate_type(value, "integer", key) when is_binary(value) do
    case Integer.parse(value) do
      {_int, ""} ->
        true

      _ ->
        error_tuple(
          key,
          value,
          "invalid value for #{key}: expected integer, got: #{inspect(value)}"
        )
    end
  end

  defp validate_type(value, "integer", _key) when is_integer(value), do: true

  defp validate_type(value, "string", _key) when is_binary(value), do: true

  defp validate_type(value, "map", _key) when is_map(value), do: true

  defp validate_type(value, type, key) do
    error_tuple(
      key,
      value,
      "invalid value for #{key}: expected #{type}, got: #{inspect(value)}"
    )
  end

  defp handle_missing_key(_data, key, opts, acc) do
    if opts["required"] do
      error_tuple(
        key,
        nil,
        "#{key} is required but not provided"
      )
    else
      if Map.has_key?(opts, "default") do
        {:ok, Map.put(acc, key, opts["default"])}
      else
        {:ok, acc}
      end
    end
  end

  defp transform_schema(nil), do: %{}

  defp transform_schema(schema) do
    Enum.reduce(schema, %{}, fn {k, v}, acc ->
      updated_v =
        if v["type"] == "map" do
          Map.put(v, "keys", transform_schema(v["keys"]))
        else
          v
        end

      Map.put(acc, k, Map.update!(updated_v, "type", & &1))
    end)
  end

  defp error_tuple(key, value, message) do
    {:error, %ValidationError{key: key, message: message, value: value}}
  end
end
