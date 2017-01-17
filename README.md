# Limiter

[![Build Status](https://travis-ci.org/jur0/limiter.svg?branch=master)](https://travis-ci.org/jur0/limiter)

Rate limiter implementation of Generic Cell Rate Algorithm (GCRA).

For detailed information on how the algorithm works, please check the following
links:

  * [Rate limiting, Cells and GCRA](https://brandur.org/rate-limiting)
  * [GCRA algorithm](https://en.wikipedia.org/wiki/Generic_cell_rate_algorithm)

The implementation is similar to Go `throttled` library:

  * [Go throttled library](https://github.com/throttled/throttled)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `limiter` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:limiter, "~> 0.1.2"}]
    end
    ```

  2. Ensure `limiter` is started before your application:

    ```elixir
    def application do
      [applications: [:limiter]]
    end
    ```

## Usage

First off, a storage must be configured and started. Currently, the rate
limiter supports one implementation of the storage, which is
`Limiter.Storage.ConCache`. Each implementation of the storage can have
different options.

The storage can be started in two ways:

  * as a part of the `limiter`'s supervision tree - the config of the
  `limiter`'s storage is in the config file. For example:

    ```elixir
    config :limiter,
      storage: [{Limiter.Storage.ConCache, :limiter_con_cache}]

    config :limiter, :limiter_con_cache,
      ttl_check: 1_000
    ```

  * as a part of the supervision tree of the application which is using the
  `limiter` (so the storage can be restarted with that application) -
  `Limiter.Storage.ConCache` exports `start_link/1` function, so it can be
  added to the supervision tree, for example:

    ```elixir
    children = [
      ...
      worker(Limiter.Storage.ConCache, [
        [name: :limiter_con_cache, ttl_check: 1_000]
      ])
    ]
    ...
    Supervisor.start_link(children, ...)
    ```

The `Limiter` module exports `checkout/5` with the following arguments:

  * `storage` - tuple that contains the module used for storage
  (`Limiter.Storage.ConCache`) and options for the given storage.
  * `key` - the key associated with an action which is rate limited.
  * `quantity` - the weight of an action. Typically it's set to `1`. The more
  expensive actions may use greater value.
  * `period` -  the period of time that along with `limit` defines the rate
  limit.
  * `limit` - the number of actions (in case the `quantity` is `1`) that
  along with the `period` defines the rate limit.

Example:

```elixir
Limiter.checkout({Limiter.Storage.ConCache, :limiter_con_cache}, "key", 1, 10_000, 5)
```

The `Limiter.checkout/5` functions returns a struct (`Limiter.Result`) with the
following information:

  * `allowed` - indicates if an action is allowed or rate limited.
  * `remaining` - the number of actions that is allowed before reaching the rate
  limit.
  * `reset_after` - how long (in milliseconds) it will take for the given key
  to get to the initial state.
  * `retry_after` -  how long (in milliseconds) it will take for the next
  action (associated with the given key) to be allowed.
