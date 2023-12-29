defmodule Spector.Validator do
  @callback validate(any()) :: {:error, Spector.ValidationError.t()} | {:ok, any()}
end
