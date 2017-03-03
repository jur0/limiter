defmodule Limiter.Mixfile do
  use Mix.Project

  @version "0.1.2"

  def project do
    [app: :limiter,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     deps: deps(),
     docs: docs(),
     package: package()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Limiter.Application, []}]
  end

  defp description do
    "GCRA rate limiter"
  end

  defp deps do
    [{:con_cache, "~> 0.12"},
     {:ex_doc, "~> 0.14", only: :dev}]
  end

  defp docs do
    [source_url: "https://github.com/jur0/limiter",
     source_ref: @version,
     extras: ["README.md"]]
  end

  defp package do
    [maintainers: ["Juraj Hlista"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/jur0/limiter"}]
  end
end
