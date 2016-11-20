# Limiter

Elixir rate limiter implementation of Generic Cell Rate Algorithm (GCRA).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `limiter` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:limiter, "~> 0.1.0"}]
    end
    ```

  2. Ensure `limiter` is started before your application:

    ```elixir
    def application do
      [applications: [:limiter]]
    end
    ```

