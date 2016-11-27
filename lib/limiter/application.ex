defmodule Limiter.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = storage_workers()
    opts = [strategy: :one_for_one, name: Limiter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp storage_workers do
    for {mod, name} <- Application.get_env(:limiter, :storage, []) do
      args = [Application.get_env(:limiter, name) ++ [name: name]]
      id = {mod, name}
      worker(mod, args, id: id)
    end
  end
end
