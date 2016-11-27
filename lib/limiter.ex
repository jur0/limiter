defmodule Limiter.Result do
  @moduledoc """
  The struct is the result of calling `Limiter.checkout/5` function.
  """

  @typedoc """
  Indicates if an action is allowed or rate limited.
  """
  @type allowed :: boolean

  @typedoc """
  The number of actions that is allowed before reaching the rate limit.
  """
  @type remaining :: non_neg_integer

  @typedoc """
  How long (in milliseconds) it will take for the given key to get to the
  initial state.
  """
  @type reset_after :: non_neg_integer

  @typedoc """
  How long (in milliseconds) it will take for the next action (associated with
  the given key) to be allowed.
  """
  @type retry_after :: non_neg_integer

  @typedoc """
  The result map.
  """
  @type t :: %Limiter.Result{allowed: allowed, remaining: remaining,
    reset_after: reset_after, retry_after: retry_after}

  defstruct allowed: true, remaining: 0, reset_after: 0, retry_after: 0
end

defmodule Limiter do
  @moduledoc """
  Rate limiter implementation based on Generic Cell Rate Algorithm (GCRA).

  The limiter checks if a given key exceeded a rate limit and returns the
  result with additional info.

  For more details, see the below links:

    * [Rate limiting, Cells and GCRA](https://brandur.org/rate-limiting)
    * [Go throttled library](https://github.com/throttled/throttled)
    * [GCRA algorithm](https://en.wikipedia.org/wiki/Generic_cell_rate_algorithm)

  Example usage:

      Limiter.checkout({Limiter.Storage.ConCache, :storage}, "key", 10_000, 5)

  """

  alias Limiter.Result

  @typedoc """
  Tuple that contains the module used for storage and options for the given
  storage.
  """
  @type storage :: {storage_module, storage_options}

  @typedoc """
  Storage module that implements `Limiter.Storage` behaviour.
  """
  @type storage_module :: module

  @typedoc """
  Options for a storage module. These options may differ for different storage
  implementations.
  """
  @type storage_options :: term

  @typedoc """
  The key associated with an action which is rate limited.
  """
  @type key :: term

  @typedoc """
  The weight of an action. Typically it's set to `1`. The more expensive
  actions may use greater value.
  """
  @type quantity :: pos_integer

  @typedoc """
  The period of time that along with `limit` defines the rate limit.
  """
  @type period :: pos_integer

  @typedoc """
  The number of actions (in case the `quantity` is `1`) that along with
  the `period` defines the rate limit.
  """
  @type limit :: non_neg_integer

  @doc """
  Checks if an action associated with a key is allowed.
  """
  @spec checkout(storage, key, quantity, period, limit) :: Result.t
  def checkout(storage, key, quantity \\ 1, period, limit) do
    now = time()
    dvt = period * limit
    inc = quantity * period
    max_tat = now + dvt
    tat = get_and_store(storage, key, now, inc, max_tat)
    new_tat = tat + inc
    allow_at = new_tat - dvt
    diff = now - allow_at
    {result, ttl} = if (diff < 0) do
      retry_after = if (inc <= dvt), do: -diff, else: 0
      {%Result{allowed: false, retry_after: retry_after}, tat - now}
    else
      {%Result{}, new_tat - now}
    end
    next = dvt - ttl
    if (next > -period) do
      %{result | remaining: round(next / period) |> max(0), reset_after: ttl}
    else
      %{result | reset_after: ttl}
    end
  end


  @doc """
  Resets the value associated with the key.
  """
  @spec reset(storage, key) :: :ok
  def reset({mod, opts}, key), do: mod.reset(opts, key)

  defp get_and_store({mod, opts}, key, now, inc, max_tat),
    do: mod.get_and_store(opts, key, now, inc, max_tat)

  defp time(), do: System.system_time(:milliseconds)
end
