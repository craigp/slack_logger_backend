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
    [{:slack_logger_backend, "~> 0.0.1"}]
  end
  ```

  Then run `$ mix do deps.get, compile` to download and compile your
  dependencies.

  Finally, add `SlackLoggerBackend.Logger` to your list of logging backends in
  your app's config:

  ```elixir
  config :logger, backends: [SlackLoggerBackend.Logger, :console]
  ```

  You can set the log levels you want posted to slack in the config:

  ```elixir
  config SlackLoggerBackend, :levels, [:debug, :info, :warn, :error]
  ```

  Alternatively, do both in one step:

  ```elixir
  config :logger, backends: [{SlackLoggerBackend.Logger, :error}]
  config :logger, backends: [{SlackLoggerBackend.Logger, [:info, error]}]
  ```

  You'll need to create a custom incoming webhook URL for your Slack team. You
  can either configure the webhook in your config:

  ```elixir
  config SlackLoggerBackend, :slack, [url: "http://example.com"]
  ```

  ... or you can put the webhook URL in the `SLACK_LOGGER_WEBHOOK_URL`
  environment variable if you prefer. If you have both the environment variable
  will be preferred.
  """

  use Application
  alias SlackLoggerBackend.{Pool, Formatter, Producer, Consumer}

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Producer, []),
      worker(Formatter, [10, 5]),
      worker(Consumer, [10, 5]),
      worker(Pool, [10])
    ]

    opts = [strategy: :one_for_one, name: SlackLoggerBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc false
  def stop(_args) do
    # noop
  end
end
