defmodule Spector.Test.CustomValidator do
  @behaviour Spector.Validator

  @impl Spector.Validator
  def validate("valid"), do: true

  def validate(value),
    do: {:error, %Spector.ValidationError{message: "invalid value", value: value}}
end
