defmodule Spector do
  @moduledoc """
  A tiny library for validating and documenting specs.

  Spector allows developers to create schemas using a
  pre-defined set of options and types. The main benefits are:

    * A single unified way to define simple schema
    * Specs validation against schemas

  ## Schema Options

  These are the options supported in a *schema*. They are what
  defines the validation for the items in the given schema.

  ## Types

    * `:list` - A list.

    * `:non_empty_list` - A non-empty list.

    * `:map` - A map consisting of `string` keys.
      Keys can be specified using the `keys` option.

    * `:string` - A string.

    * `:boolean` - A boolean.

    * `:integer` - An integer.

    * `:non_neg_integer` - A non-negative integer.

    * `:float` - A float.
  """

  @schema %{
    "type" => %{
      "type" => "string",
      "default" => "string",
      "doc" => "The type of the option item."
    },
    "required" => %{
      "type" => "boolean",
      "default" => false,
      "doc" => "Defines if the option item is required."
    },
    "default" => %{
      "type" => "any",
      "doc" => """
      The default value for the option item if that option is not specified. This value
      is *validated* according to the given `:type`. This means that you cannot
      have, for example, `type: :integer` and use `default: "a string"`.
      """
    },
    "keys" => %{
      "type" => "list",
      "doc" => """
      Available for types `:list`, `:non_empty_list`, and `:map`,
      it defines which set of keys are accepted for the option item. The value of the
      `:keys` option is a schema itself. For example: `keys: [foo: [type: :atom]]`.
      """,
      "keys" => &__MODULE__.schema/0
    },
    "doc" => %{
      "type" => "string",
      "doc" => "The documentation for the option item."
    }
  }

  alias Spector.ValidationError

  def schema(), do: @schema

  def custom_types(), do: Application.get_env(:spector, :custom_types, %{})

  def custom_type(type) do
    custom_types()
    |> Map.get(type)
  end

  @doc """
  Validates the given `data` against the given `schema`.

  ## Example:

      iex> Spector.validate(%{"foo" => 1}, %{"foo" => %{"type" => "map"}})
      {:error,
       %Spector.ValidationError{
         __exception__: true,
         key: "foo",
         keys_path: [],
         message: "invalid value for \"foo\" key: expected map, got: 1",
         value: 1
       }}
  """
  @spec validate(map(), map()) :: {:ok, map()} | {:error, ValidationError.t()}
  def validate(data, schema) when is_map(data) and is_map(schema) do
    validate_map(data, transform_schema(schema))
  end

  @doc """
  Validates the given `data` against the given `schema` in the given `format`.

  ## Example:

      iex> Spector.validate(%{"foo" => 1}, %{"foo" => %{"type" => "map"}}, :json)
      {:error,
       %Spector.ValidationError{
         __exception__: true,
         key: "foo",
         keys_path: [],
         message: "invalid value for \"foo\" key: expected map, got: 1",
         value: 1
       }}
  """
  @spec validate(any(), any(), :json | :yaml) ::
          {:error, Spector.ValidationError.t()} | {:ok, map()}
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
          else:
            error_tuple(
              key,
              nil,
              "#{render_key(key)} is required but not provided"
            )

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

  defp validate_type(value, "float", _key) when is_float(value),
    do: true

  defp validate_type(value, "float", key) when is_binary(value) do
    case Float.parse(value) do
      {_float, ""} ->
        true

      _ ->
        error_tuple(
          key,
          value,
          "invalid value for #{render_key(key)}: expected float, got: #{inspect(value)}"
        )
    end
  end

  defp validate_type(value, "non_neg_integer", _key) when is_integer(value) and value >= 0,
    do: true

  defp validate_type(value, "boolean", _key) when is_boolean(value), do: true

  defp validate_type(value, "integer", key) when is_binary(value) do
    case Integer.parse(value) do
      {_int, ""} ->
        true

      _ ->
        error_tuple(
          key,
          value,
          "invalid value for #{render_key(key)}: expected integer, got: #{inspect(value)}"
        )
    end
  end

  defp validate_type(value, "integer", _key) when is_integer(value), do: true

  defp validate_type(value, "string", _key) when is_binary(value), do: true

  defp validate_type(value, "map", _key) when is_map(value), do: true

  defp validate_type(value, "list", _key) when is_list(value), do: true

  defp validate_type(value, type, key) do
    case custom_type(type) do
      nil ->
        error_tuple(
          key,
          value,
          "invalid value for #{render_key(key)}: expected #{type}, got: #{inspect(value)}"
        )

      validator ->
        validator.(value)
    end
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

  defp render_key(key), do: inspect(key) <> " key"
end
