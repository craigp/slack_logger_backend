defmodule SlackLoggerBackend.FormatHelper do
  @moduledoc """
  Simple formatter for Slack messages.
  """

  @doc """
  Formats a log event for Slack.
  """
  def format_event(detail) do
    fields =
      [
        field("Level", detail, :level),
        field("Deployment", deployment()),
        field("Application", detail, :application),
        field("Module", detail, :module),
        field("Function", detail, :function),
        field("File", detail, :file),
        field("Line", detail, :line),
        field("Count", detail, :count)
      ]
      |> Enum.reject(&is_nil/1)

    {:ok, json} =
      %{
        attachments: [
          %{
            fallback: "An #{detail.level} level event has occurred: #{detail.message}",
            pretext: detail.message,
            fields: fields
          }
        ]
      }
      |> Jason.encode()

    json
  end

  defp deployment() do
    System.get_env(
      "SLACK_LOGGER_DEPLOYMENT_NAME",
      Application.get_env(
        :slack_logger_backend,
        :deployment_name
      )
    )
  end

  defp field(title, map, key), do: field(title, map[key])
  defp field(_, nil), do: nil

  defp field(title, value) do
    %{
      title: title,
      value: value,
      short: true
    }
  end

  def scrub(message, nil), do: message
  def scrub(message, []), do: message

  def scrub(message, [scrubber | scrubbers]),
    do: message |> scrub(scrubber) |> scrub(scrubbers)

  def scrub(message, {regex, substitution}),
    do: String.replace(message, regex, substitution, global: true)

  def scrub(message, regex),
    do: String.replace(message, regex, "--redacted--", global: true)
end
