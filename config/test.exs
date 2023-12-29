import Config

config :spector, :custom_types, %{
  "custom" => &Spector.Test.CustomValidator.validate/1
}
