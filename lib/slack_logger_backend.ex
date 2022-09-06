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

  You can also put the webhook URL in the `SLACK_LOGGER_WEBHOOK_URL` environment variable. If
  you have both the environment variable will take priority.

  If you want to prevent the same message from being spammed in the slack channel you can set a
  debounce, which will send the message with a count of the number of occurances of the message
  within the debounce period:

  ```
  config :slack_logger_backend, debounce_seconds: 300
  ```

  An optional field labeled "Deployment" is availiable in the Slack messages. This is useful if you
  have multiple deployments send messages to the same Slack thread. This value can be set in
  config (see below) or using the environment variable `SLACK_LOGGER_DEPLOYMENT_NAME`. The
  environment variable will take priority.

  ```
  config :slack_logger_backend, deployment_name: "example deployment",
  ```
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
