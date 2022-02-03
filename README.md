slack_logger_backend
====================
[![Build Status](https://secure.travis-ci.org/craigp/slack_logger_backend.png?branch=master "Build Status")](http://travis-ci.org/craigp/slack_logger_backend)
[![Coverage Status](https://coveralls.io/repos/craigp/slack_logger_backend/badge.svg?branch=master&service=github)](https://coveralls.io/github/craigp/slack_logger_backend?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/slack_logger_backend.svg)](https://hex.pm/packages/slack_logger_backend)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/slack_logger_backend.svg)](https://hex.pm/packages/slack_logger_backend)
[![Inline docs](http://inch-ci.org/github/craigp/slack_logger_backend.svg?branch=master&style=flat)](http://inch-ci.org/github/craigp/slack_logger_backend)

A logger backend for posting errors to Slack.

You can find the hex package [here](https://hex.pm/packages/slack_logger_backend), and the docs [here](http://hexdocs.pm/slack_logger_backend).

## Usage

First, add the client to your `mix.exs` dependencies:

```elixir
def deps do
  [{:slack_logger_backend, "~> 0.2.0"}]
end
```

Then run `$ mix do deps.get, compile` to download and compile your dependencies.

Add the `:slack_logger_backend` application as your list of applications in `mix.exs`:

```elixir
def application do
  [applications: [:logger, :slack_logger_backend]]
end
```

Add `SlackLoggerBackend.Logger` to your list of logging backends in your app's config:

```elixir
config :logger, backends: [:console, {SlackLoggerBackend.Logger, :error}]
```

You'll need to create a custom incoming webhook URL for your Slack team. You can either configure the webhook
in your config:

```elixir
config :slack_logger_backend, slack_webhook: "http://example.com"
```

You can also put the webhook URL in the `SLACK_LOGGER_WEBHOOK_URL` environment variable. If
you have both the environment variable will take proirity.

If you want to prevent the same message from being spammed in the slack channel you can set a 
debounce, which will send the message with a count of the number of occurances of the message 
within the debounce period:

```
config :slack_logger_backend, debounce_seconds: 300
```