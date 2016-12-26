defmodule Limiter.Storage.ConCache do
  @moduledoc false

  @behaviour Limiter.Storage
  alias ConCache.Item

  @doc """
  Starts the `con_cache` server process.

  ## Options

    * `:name` - must be present. It's the unique name of the storage.
    * `:ttl_check` - how often the TTL value of the entries in the storage
    is checked. The entries with expired TTL are removed. The default value
    is 1000 ms.
  """
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    ttl_check = Keyword.get(opts, :ttl_check, 1_000)

    opts = [:set, :named_table, name: name, touch_on_read: false,
     write_concurrency: true, read_concurrency: true,
     ttl_check: ttl_check, ttl: 1_000]

    gen_server_opts = [name: name]

    ConCache.start_link(opts, gen_server_opts)
  end

  @doc """
  Implements `get_and_store/5` callback from `Limiter.Storage`.
  """
  def get_and_store(name, key, now, inc, max_tat) do
    ConCache.isolated(name, key, fn() ->
      case ConCache.get(name, key) do
        nil ->
          new_tat = now + inc
          ConCache.dirty_put(name, key, %Item{value: new_tat, ttl: inc})
          now
        tat ->
          new_tat = tat + inc
          ttl = new_tat - now
          if new_tat <= max_tat,
            do: ConCache.dirty_put(name, key, %Item{value: new_tat, ttl: ttl})
          tat
      end
    end)
  end

  @doc """
  Implements `reset/2` callback from `Limiter.Storage`.
  """
  def reset(name, key) do
    ConCache.delete(name, key)
  end
end
