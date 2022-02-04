defmodule SlackLoggerBackend.FormatHelper do
  @moduledoc """
  Simple formatter for Slack messages.
  """

  import Poison, only: [encode: 1]

  @doc """
  Formats a log event for Slack.
  """
  def format_event(detail) do
    deployment = System.get_env("SLACK_LOGGER_DEPLOYMENT_NAME")

    fields =
      [
        field("Level", detail, :level),
        field("Deployment", deployment),
        field("Application", detail, :application),
        field("Module", detail, :module),
        field("Function", detail, :function),
        field("File", detail, :file),
        field("Line", detail, :line),
        field("Count", detail, :count)
      ]
      |> Enum.reject(&is_nil/1)

    message = messge_to_string(detail.message)

    {:ok, json} =
      %{
        attachments: [
          %{
            fallback: "An #{detail.level} level event has occurred: #{message}",
            pretext: message,
            fields: fields
          }
        ]
      }
      |> encode

    json
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

  defp messge_to_string(a) when is_binary(a) do
    a
  end

  defp messge_to_string([a]) do
    messge_to_string(a)
  end

  defp messge_to_string(["\nState: " | _]) do
    ""
  end

  defp messge_to_string([a | b]) do
    messge_to_string([messge_to_string(a) <> messge_to_string(b)])
  end

  defp messge_to_string(a) do
    inspect(a)
  end
end
