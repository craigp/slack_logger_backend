defmodule SlackLoggerBackend.FormatHelper do
  @moduledoc """
  Simple formatter for Slack messages.
  """

  import Poison, only: [encode: 1]

  @doc """
  Formats a log event for Slack.
  """
  def format_event({level, message, application, module, function, file, line})
      when is_nil(application) and is_nil(module) and is_nil(function) and is_nil(file) and
             is_nil(line) do
    {:ok, event} =
      %{
        attachments: [
          %{
            fallback: "An #{level} level event has occurred: #{message}",
            pretext: message
          }
        ]
      }
      |> encode

    event
  end

  @doc """
  Formats a log event for Slack.
  """

  def format_event({level, message, application, module, function, file, line}) do
    {:ok, event} =
      %{
        attachments: [
          %{
            fallback: "An #{level} level event has occurred: #{message}",
            pretext: message,
            fields: [
              %{
                title: "Level",
                value: level,
                short: true
              },
              %{
                title: "Application",
                value: application,
                short: true
              },
              %{
                title: "Module",
                value: module,
                short: true
              },
              %{
                title: "Function",
                value: function,
                short: true
              },
              %{
                title: "File",
                value: file,
                short: true
              },
              %{
                title: "Line",
                value: line,
                short: true
              }
            ]
          }
        ]
      }
      |> encode

    event
  end
end
