defmodule SlackLoggerBackend do
  @moduledoc """
  A logger backend for posting errors to Slack.

  You can find the hex package
  [here](https://hex.pm/packages/slack_logger_backend), and the docs
  [here](http://hexdocs.pm/slack_logger_backend).

  ## Usage

  First, add the client to your `mix.exs` dependencies:

  ```elixir
  def deps do
    [{:slack_logger_backend, "~> 0.2.0"}]
  end
  ```

  Then run `$ mix do deps.get, compile` to download and compile your
  dependencies.

  Finally, add `SlackLoggerBackend.Logger` to your list of logging backends in
  your app's config:

  ```elixir
  config :logger, backends: [:console, {SlackLoggerBackend.Logger, :error}]
  ```

  You'll need to create a custom incoming webhook URL for your Slack team. You
  can either configure the webhook in your config:

  ```elixir
  config :slack_logger_backend, :slack, [url: "http://example.com"]
  ```

  ... or you can put the webhook URL in the `SLACK_LOGGER_WEBHOOK_URL`
  environment variable if you prefer. If you have both the environment variable
  will be preferred.
  """

  use Application
  alias SlackLoggerBackend.{Pool, Formatter, Producer, Consumer}

  @doc false
  def start(_type, _args) do
    children = [
      Producer,
      {Formatter, [10, 5]},
      {Consumer, [10, 5]},
      {Pool, [10]}
    ]

    opts = [strategy: :one_for_one, name: SlackLoggerBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc false
  def stop(_args) do
    # noop
  end
end
