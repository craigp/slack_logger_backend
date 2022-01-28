defmodule SlackLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slack_logger_backend,
      description: "A logger backend for posting errors to Slack.",
      version: "0.2.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test],
      package: package()
    ]
  end

  def application do
    [applications: [:logger, :httpoison, :gen_stage], mod: {SlackLoggerBackend, []}]
  end

  defp deps do
    [
      {:gen_stage, "~> 1.1"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 5.0"},
      {:poolboy, "~> 1.5.1"},
      {:excoveralls, "~> 0.14", only: :test},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.28", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev},
      {:bypass, "~> 2.1", only: :test},
      {:inch_ex, "~> 2.0", only: :docs},
      {:credo, "~> 1.6", only: :dev}
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*"],
      licenses: ["MIT"],
      maintainers: ["Craig Paterson"],
      links: %{"Github" => "https://github.com/craigp/slack_logger_backend"}
    ]
  end
end
