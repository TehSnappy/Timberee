defmodule Timberee.Scenic.MixProject do
  use Mix.Project

  def project do
    [
      app: :timberee_scenic,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      TimbereeScenic: %{
        id: TimbereeScenic,
        start: {TimbereeScenic, :start_link, [restart: :permanent]}
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.11.0", override: true},
      {:scenic_driver_local, "0.12.0-rc.0"},
      {:scenic_clock, "~> 0.11.0"},
      {:elixir_make, "~> 0.9.0", override: true}
    ]
  end
end
