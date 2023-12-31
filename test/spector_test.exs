defmodule SpectorTest do
  use ExUnit.Case, async: true

  describe "validate/2" do
    test "custom_types/0" do
      assert %{"custom" => _} = Spector.custom_types()
    end

    test "validate/2 returns {:ok, %{}} when given an empty map and an empty schema" do
      assert {:ok, %{}} = Spector.validate(%{}, %{})
    end

    test "validate/2 returns {:ok, %{}} when given a map with a single key and an empty schema" do
      assert {:ok, %{"foo" => 1}} =
               Spector.validate(%{"foo" => 1}, %{"foo" => %{"type" => "integer"}})
    end

    test "validate/2 returns {:error, %{}} when data doesn't match schema" do
      assert {:error,
              %Spector.ValidationError{
                __exception__: true,
                key: "foo",
                keys_path: [],
                message: "invalid value for \"foo\" key: expected map, got: 1",
                value: 1
              }} =
               Spector.validate(%{"foo" => 1}, %{"foo" => %{"type" => "map"}})
    end

    test "validate/2 returns {:ok, %{}} with valid string" do
      assert {:ok, %{"foo" => "valid"}} =
               Spector.validate(%{"foo" => "valid"}, %{"foo" => %{"type" => "string"}})
    end

    @tag :list
    test "validate/2 returns {:ok, %{}} with valid list" do
      schema = %{
        "foo" => %{"type" => "string"},
        "names" => %{
          "type" => "list",
          "required" => true,
          "keys" => %{"name" => %{"type" => "string"}}
        }
      }

      assert {:ok, %{"foo" => "valid", "names" => [%{"name" => "peter"}, %{"name" => "pan"}]}} =
               Spector.validate(%{"foo" => "valid", "names" => [%{"name" => "peter"}, %{"name" => "pan"}]}, schema)
    end

    test "validate/2 returns {:ok, %{}} with valid boolean" do
      assert {:ok, %{"foo" => true}} =
               Spector.validate(%{"foo" => true}, %{"foo" => %{"type" => "boolean"}})
    end

    test "validate/2 returns {:ok, %{}} with valid float" do
      assert {:ok, %{"foo" => 2.3}} =
               Spector.validate(%{"foo" => 2.3}, %{"foo" => %{"type" => "float"}})

      assert {:ok, %{"foo" => "2.3"}} =
               Spector.validate(%{"foo" => "2.3"}, %{"foo" => %{"type" => "float"}})
    end

    test "validate/2 with custom types" do
      assert {:ok, %{"foo" => "valid"}} =
               Spector.validate(%{"foo" => "valid"}, %{"foo" => %{"type" => "custom"}})

      assert {:error,
              %Spector.ValidationError{
                __exception__: true,
                key: nil,
                keys_path: [],
                message: "invalid value",
                value: "invalid"
              }} =
               Spector.validate(%{"foo" => "invalid"}, %{"foo" => %{"type" => "custom"}})
    end

    test "validate/2 returns {:ok, %{}} with valid non_neg_integer" do
      assert {:ok, %{"foo" => 2}} =
               Spector.validate(%{"foo" => 2}, %{"foo" => %{"type" => "non_neg_integer"}})

      assert {
               :error,
               %Spector.ValidationError{
                 __exception__: true,
                 key: "foo",
                 keys_path: [],
                 message: "invalid value for \"foo\" key: expected non_neg_integer, got: -2",
                 value: -2
               }
             } =
               Spector.validate(%{"foo" => -2}, %{"foo" => %{"type" => "non_neg_integer"}})
    end

    test "validate/2 returns {:error, %{}} with not required value provided" do
      assert {:error,
              %Spector.ValidationError{
                message: "foo is required but not provided",
                key: "foo",
                value: nil,
                keys_path: []
              }} =
               Spector.validate(%{}, %{"foo" => %{"type" => "string", "required" => true}})
    end

    test "validate/2 returns {:error, %{}} with invalid values" do
      assert {:error,
              %Spector.ValidationError{
                message: "invalid value for \"foo\" key: expected integer, got: \"not_a_number\"",
                key: "foo",
                value: "not_a_number",
                keys_path: []
              }} =
               Spector.validate(%{"foo" => "not_a_number"}, %{"foo" => %{"type" => "integer"}})
    end

    test "validate/2 returns {:ok, %{}} with nested valid string" do
      schema = %{"foo" => %{"type" => "map", "keys" => %{"bar" => %{"type" => "string"}}}}
      data = %{"foo" => %{"bar" => "hello"}}

      assert {:ok, ^data} =
               Spector.validate(data, schema)
    end

    test "validate/2 returns {:error, %{}} with nested invalid string" do
      schema = %{"foo" => %{"type" => "map", "keys" => %{"bar" => %{"type" => "string"}}}}
      data = %{"foo" => %{"bar" => 1234}}

      assert {
               :error,
               %Spector.ValidationError{
                 key: "bar",
                 keys_path: [],
                 message: "invalid value for \"bar\" key: expected string, got: 1234",
                 value: 1234,
                 __exception__: true
               }
             } = Spector.validate(data, schema)
    end

    test "validate/2 single from yaml" do
      data = """
      name: "Peter"
      """

      schema = """
      name:
        type: string
        required: true
      """

      assert {:ok, %{"name" => "Peter"}} = Spector.validate(data, schema, :yaml)
    end

    test "validate/2 nested keys from yaml" do
      data = """
      person:
        name: "Parker"
        surname: "Parker"
        age: 25
      """

      schema = """
      person:
        type: map
        required: true
        keys:
          name:
            type: string
          surname:
            type: string
            required: true
          age:
            type: integer
            required: true
      """

      assert {:ok, %{"person" => %{"age" => 25, "name" => "Parker", "surname" => "Parker"}}} =
               Spector.validate(data, schema, :yaml)

      data = """
      person:
        surname: "Parker"
        age: 25
      """

      assert {:ok, %{"person" => %{"age" => 25, "surname" => "Parker"}}} =
               Spector.validate(data, schema, :yaml)

      invalid_data = """
      person:
        age: 25
      """

      assert {:error,
              %Spector.ValidationError{
                __exception__: true,
                key: "surname",
                keys_path: [],
                message: "surname is required but not provided",
                value: nil
              }} =
               Spector.validate(invalid_data, schema, :yaml)
    end

    test "validate/2 nested keys from json" do
      data = """
      {
        "person": {
          "name": "Parker",
          "surname": "Parker",
          "age": 25
        }
      }
      """

      schema = """
      {
        "person": {
          "type": "map",
          "required": true,
          "keys": {
            "name": {
              "type": "string"
            },
            "surname": {
              "type": "string",
              "required": true
            },
            "age": {
              "type": "integer",
              "required": true
            }
          }
        }
      }
      """

      assert {:ok, %{"person" => %{"age" => 25, "name" => "Parker", "surname" => "Parker"}}} =
               Spector.validate(data, schema, :json)

      data = """
      {
        "person": {
          "surname": "Parker",
          "age": 25
        }
      }
      """

      assert {:ok, %{"person" => %{"age" => 25, "surname" => "Parker"}}} =
               Spector.validate(data, schema, :json)

      invalid_data = """
      {
        "person": {
          "age": 25
        }
      }
      """

      assert {:error,
              %Spector.ValidationError{
                __exception__: true,
                key: "surname",
                keys_path: [],
                message: "surname is required but not provided",
                value: nil
              }} =
               Spector.validate(invalid_data, schema, :json)
    end
  end
end
