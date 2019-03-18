defmodule SlackLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slack_logger_backend,
      description: "A logger backend for posting errors to Slack.",
      version: "0.1.19",
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
      {:httpoison, "~> 0.10"},
      {:poison, "~> 2.2 or ~> 4.1"},
      {:gen_stage, "~> 0.11"},
      {:poolboy, "~> 1.5.1"},
      {:excoveralls, "~> 0.5", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.3", only: :dev},
      {:bypass, "~> 1.0.0", only: :test},
      {:inch_ex, "~> 0.5", only: :docs},
      {:credo, "~> 0.5", only: :dev}
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
