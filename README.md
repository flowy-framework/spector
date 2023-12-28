<p align="center">
  <img width="140px" src="assets/logo-small.png">
  
  <h1 align="center">Spector</h1>
  
  <p align="center">
    A tiny library for validating and documenting specs.
  </p>
</p>


<p align="center">
  <a href="#">
    <img alt="Build Status" src="https://github.com/flowy-framework/spector/actions/workflows/main.yml/badge.svg">
  </a>
  <a href="https://codecov.io/gh/flowy-framework/spector">
    <img src="https://codecov.io/gh/flowy-framework/spector/graph/badge.svg?token=UMpPVA0S3j"/>
  </a>
  <a href="https://github.com/flowy-framework/spector">
    <img src="https://img.shields.io/github/last-commit/flowy-framework/spector.svg"/>
  </a>
</p>


## Acknowledgments and Credits
This library is heavily inspired by and based upon the work done in [NimbleOptions](https://github.com/dashbitco/nimble_options) by Dashbitco. We extend our sincere gratitude and acknowledgment to the creators and contributors of NimbleOptions for their innovative and foundational work in this field. Our library builds upon the concepts and implementations found in NimbleOptions, and we encourage users to refer to the original project for further insights and context.

We would like to explicitly thank the Dashbitco team and contributors to NimbleOptions for their contributions to the open-source community, which have significantly influenced the development of our library.

## Intro 

This library allows you to validate specs based on a definition.
A definition is a map specifying how the specs you want
to validate should look like:

```elixir
definition = %{
  connections: %{
    type: :non_neg_integer,
    default: 5
  },
  url: %{
    type: :string,
    required: true
  }
}
```

Now you can validate options through `Spector.validate/2`:

```elixir
options = %{url: "https://example.com"}

Spector.validate(options, definition)
#=> {:ok, %{url: "https://example.com", connections: 5}}
```

If the options don't match the definition, an error is returned:

```elixir
Spector.validate([connections: 3], definition)
{:error,
 %Spector.ValidationError{
   keys_path: [],
   message: "required option :url not found, received options: [:connections]"
 }}
```

`Spector` is also capable of automatically generating
documentation for a definition by calling `Spector.docs/1`
with your definition.

## Installation

You can install `spector` by adding it to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spector, "~> 0.1"}
  ]
end
```

[docs]: https://hexdocs.pm/spector
