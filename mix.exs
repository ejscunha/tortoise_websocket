defmodule TortoiseWebsocket.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :tortoise_websocket,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/tortoise/tortoise_websocket"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TortoiseWebsocket.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_state_machine, "~> 2.0"},
      {:gun, "~> 1.3"},
      {:socket, "~> 0.3"},
      {:tortoise, github: "ejscunha/tortoise", branch: "feature/websocket-support"},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib"] ++ Path.wildcard("test/**/support")
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Tortoise Websocket transport."
  end

  defp package do
    [
      maintainers: ["Martin Gausby", "Eduardo Cunha"],
      licenses: ["Apache 2.0"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => "https://github.com/tortoise/tortoise_websocket"}
    ]
  end

  defp docs do
    [
      main: "TortoiseWebsocket",
      source_ref: "v#{@version}",
      source_url: "https://github.com/tortoise/tortoise_websocket"
    ]
  end
end
