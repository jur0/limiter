defmodule Limiter.Mixfile do
  use Mix.Project

  def project do
    [app: :limiter,
     description: "GCRA rate limiter",
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :con_cache],
     mod: {Limiter.Application, []}]
  end

  defp deps do
    [{:con_cache, "~> 0.11.1"}]
  end
end
