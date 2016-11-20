defmodule Limiter.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(ConCache, [
        [ttl_check: Application.get_env(:limiter, :ttl_check, 1000),
         ttl: 5000],
        [name: :limiter_cache]])
    ]
    opts = [strategy: :one_for_one, name: Limiter.Supervisor]
    Supervisor.start_link children, opts
  end
end
