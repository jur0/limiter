defmodule Limiter.Storage do
  @moduledoc """
  Behaviour for the storage.

  The storage stores theoretical arrival time (TAT) and time to live (TTL)
  for each key.
  """

  @type options :: Limiter.storage_options

  @type key :: Limiter.key

  @type time :: non_neg_integer

  @type increment :: non_neg_integer

  @doc """
  Reads the TAT and TTL values for the given key.
  If the key:
    * is not found - the function stores the key and its value which is
    composed of the new TAT value (`now + inc`) and the TTL (`inc`).
    It returns `now`.
    * is found - the function checks if the new TAT (`new_tat == tat + inc`)
    is less than or equal to `max_tat`. If so, the value associated with the
    given key is updated: TAT is set to `new_tat` and TTL is set to
    `new_tat - now`. Otherwise, the value stays untouched. It returns the TAT
    value read from the storage.

  The function must perform the above operations atomically.
  """
  @callback get_and_store(opts :: options, key :: key, now :: time,
                          inc :: increment, max_tat :: time) :: time

  @doc """
  Resets the value (TAT and TTL) associated with the given key.
  """
  @callback reset(opts :: options, key :: key) :: :ok
end
