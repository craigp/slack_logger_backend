defmodule SlackLoggerBackend.FormatHelper do
  @moduledoc """
  Simple formatter for Slack messages.
  """

  import Poison, only: [encode: 1]

  @doc """
  Formats a log event for Slack.
  """
  def format_event(detail) do
    fields =
      [
        field("Level", detail, :level),
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
      |> encode

    json
  end

  defp field(title, map, key) do
    case map[key] do
      nil ->
        nil

      value ->
        %{
          title: title,
          value: value,
          short: true
        }
    end
  end
end
