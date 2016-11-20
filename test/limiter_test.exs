defmodule LimiterTest do
  use ExUnit.Case
  doctest Limiter

  test "zero limit" do
    assert Limiter.checkout("test_key", 100, 0) |> limited?
    assert Limiter.checkout("test_key", 100, 0) |> limited?
    assert Limiter.checkout("test_key2", 10, 1000, 0) |> limited?
  end

  test "multiple calls, same key" do
    refute Limiter.checkout("key", 100, 3) |> limited?
    refute Limiter.checkout("key", 100, 3) |> limited?
    refute Limiter.checkout("key", 100, 3) |> limited?
    assert Limiter.checkout("key", 100, 3) |> limited?
    assert Limiter.checkout("key", 100, 3) |> limited?
    assert Limiter.checkout("key", 100, 3) |> limited?
  end

  test "multiple calls, same key, changeable limit" do
    refute Limiter.checkout(:a, 200, 1) |> limited?
    refute Limiter.checkout(:a, 200, 2) |> limited?
    refute Limiter.checkout(:a, 200, 3) |> limited?
    assert Limiter.checkout(:a, 200, 3) |> limited?
    assert Limiter.checkout(:a, 200, 2) |> limited?
    assert Limiter.checkout(:a, 200, 1) |> limited?
  end

  test "reset key" do
    refute Limiter.checkout({1, 2, 3}, 100, 2) |> limited?
    refute Limiter.checkout({1, 2, 3}, 100, 2) |> limited?
    Limiter.reset({1, 2, 3})
    refute Limiter.checkout({1, 2, 3}, 100, 2) |> limited?
    refute Limiter.checkout({1, 2, 3}, 100, 2) |> limited?
    assert Limiter.checkout({1, 2, 3}, 100, 2) |> limited?
  end

  test "multiple concurrent calls, same key" do
    key = :b
    limit = 5
    processes = limit + 5
    Enum.each(1..processes,
      fn(n) ->
        if n <= limit do
          spawn(fn -> refute Limiter.checkout(key, 1000, limit) |> limited? end)
        else
          spawn(fn -> assert Limiter.checkout(key, 1000, limit) |> limited? end)
        end
      end)
  end

  # TODO: quantity, reset_after, retry_after tests

  defp limited?(%Limiter.Result{limited: limited}), do: limited
end
