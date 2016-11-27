defmodule Limiter.Storage.ConCacheTest do
  use ExUnit.Case, async: true

  import Limiter.Storage.ConCache

  setup_all do
    [_storage, {_mod, name}] = Application.get_env(:limiter, :storage)
    {:ok, name: name}
  end

  test "get_and_store", %{name: name} do
    now = 10_000
    inc = 1_000
    max_tat = now + 5_000

    Enum.each(0..5, fn(n) ->
      assert get_and_store(name, "key", now, inc, max_tat) == now + inc * n
    end)
    assert get_and_store(name, "key", now, inc, max_tat) == max_tat

    Enum.each(0..5, fn(_n) ->
      spawn(fn() ->
        get_and_store(name, "key2", now, inc, max_tat)
      end)
    end)
    :timer.sleep(10)
    assert get_and_store(name, "key2", now, inc, max_tat) == max_tat
  end

  test "get_and_store ttl", %{name: name} do
    now = 10_000
    inc = 10
    max_tat = now + 5_000

    assert get_and_store(name, :key, now, inc, max_tat) == now
    :timer.sleep(200)
    assert get_and_store(name, :key, now, inc, max_tat) == now
  end

  test "reset", %{name: name} do
    now = 10_000
    inc = 10
    max_tat = now + 5_000

    assert get_and_store(name, :a, now, inc, max_tat) == now
    assert reset(name, :a) == :ok
    assert get_and_store(name, :a, now, inc, max_tat) == now
  end
end
