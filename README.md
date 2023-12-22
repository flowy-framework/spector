# Spector

[![hex.pm badge](https://img.shields.io/badge/Package%20on%20hex.pm-informational)](https://hex.pm/packages/spector)
[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)][docs]
[![CI](https://github.com/flowy-framework/spector/actions/workflows/main.yml/badge.svg)](https://github.com/flowy-framework/spector/actions/workflows/main.yml)
[![Coverage Status](https://coveralls.io/repos/github/flowy-framework/spector/badge.svg?branch=master)](https://coveralls.io/github/flowy-framework/spector?branch=master)

[Online Documentation][docs].

A tiny library for validating and documenting specs.

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
options = [url: "https://example.com"]

Spector.validate(options, definition)
#=> {:ok, [url: "https://example.com", connections: 5]}
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
    {:spector, "~> 1.0"}
  ]
end
```

## Nimble*

All nimble libraries by Dashbit:

  * [NimbleCSV](https://github.com/flowy-framework/nimble_csv) - simple and fast CSV parsing
  * [Spector](https://github.com/flowy-framework/spector) - tiny library for validating and documenting high-level options
  * [NimbleParsec](https://github.com/flowy-framework/nimble_parsec) - simple and fast parser combinators
  * [NimblePool](https://github.com/flowy-framework/nimble_pool) - tiny resource-pool implementation
  * [NimblePublisher](https://github.com/flowy-framework/nimble_publisher) - a minimal filesystem-based publishing engine with Markdown support and code highlighting
  * [NimbleTOTP](https://github.com/flowy-framework/nimble_totp) - tiny library for generating time-based one time passwords (TOTP)

## License

Copyright 2020 Dashbit

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  > https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

[docs]: https://hexdocs.pm/spector
