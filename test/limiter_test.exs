defmodule LimiterTest do
  use ExUnit.Case, async: true

  import Limiter

  setup_all do
    [storage, _storage_small_ttl] = Application.get_env(:limiter, :storage)
    {:ok, storage: storage}
  end

  test "zero limit", %{storage: storage} do
    refute checkout(storage, "test_key", 100, 0) |> allow?
    refute checkout(storage, "test_key", 100, 0) |> allow?
    refute checkout(storage, "test_key2", 10, 5_000, 0) |> allow?
  end

  test "multiple calls, same key", %{storage: storage} do
    assert checkout(storage, "key", 100, 3) |> allow?
    assert checkout(storage, "key", 100, 3) |> allow?
    assert checkout(storage, "key", 100, 3) |> allow?
    refute checkout(storage, "key", 100, 3) |> allow?
    refute checkout(storage, "key", 100, 3) |> allow?
    refute checkout(storage, "key", 100, 3) |> allow?
  end

  test "multiple calls, same key, changeable limit", %{storage: storage} do
    assert checkout(storage, :a, 200, 1) |> allow?
    assert checkout(storage, :a, 200, 2) |> allow?
    assert checkout(storage, :a, 200, 3) |> allow?
    refute checkout(storage, :a, 200, 3) |> allow?
    refute checkout(storage, :a, 200, 2) |> allow?
    refute checkout(storage, :a, 200, 1) |> allow?
  end

  test "reset key", %{storage: storage} do
    assert checkout(storage, {1, 2, 3}, 100, 2) |> allow?
    assert checkout(storage, {1, 2, 3}, 100, 2) |> allow?
    reset(storage, {1, 2, 3})
    assert checkout(storage, {1, 2, 3}, 100, 2) |> allow?
    assert checkout(storage, {1, 2, 3}, 100, 2) |> allow?
    refute checkout(storage, {1, 2, 3}, 100, 2) |> allow?
  end

  test "multiple concurrent calls, same key", %{storage: storage} do
    key = :key
    limit = 5
    Enum.each(1..limit, fn(_n) ->
      spawn(fn -> assert checkout(storage, key, 500, limit) |> allow? end)
    end)
    :timer.sleep(10)
    Enum.each(1..limit, fn(_n) ->
      spawn(fn -> refute checkout(storage, key, 500, limit) |> allow? end)
    end)
  end

  # TODO: quantity, reset_after, retry_after tests

  defp allow?(%Limiter.Result{allowed: allowed}), do: allowed
end
