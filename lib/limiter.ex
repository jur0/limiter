defmodule Limiter.Result do
  @moduledoc """
  The struct is the result of calling `Limiter.checkout` function.

  The result map contains the following values:

    * `limited` - indicates if an action should be limited
    * `remaining` - how many actions are remainig before reaching the limit
    * `reset_after` - how long it will take to get to the iniatial state
    * `retry_after` - how long it will take for the next call/request to be
      allowed
  """

  @type t :: %Limiter.Result{limited: boolean, remaining: non_neg_integer,
    reset_after: non_neg_integer, retry_after: non_neg_integer}

  defstruct limited: false, remaining: 0, reset_after: 0, retry_after: 0
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

  Limiter.checkout("key", 10_000, 5)
  """

  alias Limiter.Result
  import ConCache, only: [delete: 2, dirty_put: 3, get: 2, isolated: 3]

  @cache :limiter_cache

  @type key :: term
  @type quantity :: pos_integer
  @type period :: pos_integer
  @type limit :: non_neg_integer

  @doc """
  Checks if an action associated with a key is limited.

  ## Arguments:

    * `key` - the key associated with an action
    * `quantity` - the weight of a given action. For example, a quantity of
      1 can be used for a single request, higher value can be used for more
      expensive operations
    * `period` - the time interval (in milliseconds). Together with `limit`,
      it determines the rate limit
    * `limit` - the number of actions (if the `quantity` is `1`) allowed
      within a `period`
  """
  @spec checkout(key, quantity, period, limit) :: Result.t
  def checkout(key, quantity \\ 1, period, limit) do
    now = System.monotonic_time :milliseconds
    dvt = period * limit
    inc = quantity * period

    {result, ttl} = isolated @cache, key, fn ->
      tat_value = get @cache, key
      tat = if tat_value == nil, do: now, else: tat_value
      tat_new = if now > tat, do: now + inc, else: tat + inc
      allow_at = tat_new - dvt
      diff = now - allow_at
      if diff < 0 do
        retry_after = if inc <= dvt, do: -diff, else: 0
        ttl = tat - now
        {%Result{limited: true, retry_after: retry_after}, ttl}
      else
        ttl = tat_new - now
        dirty_put @cache, key, %ConCache.Item{value: tat_new, ttl: ttl}
        {%Result{}, ttl}
      end
    end

    next = dvt - ttl
    result = if next > -period do
      remaining = round next / period
      remaining = if remaining < 0, do: 0, else: remaining
      %{result | remaining: remaining}
    else
      result
    end
    %{result | reset_after: ttl}
  end

  @doc """
  Resets a key.

  ## Arguments:

    * `key` - the key associated with an action
  """
  @spec reset(key) :: :ok
  def reset(key) do
    delete @cache, key
  end
end
