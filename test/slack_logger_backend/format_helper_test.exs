defmodule SlackLoggerBackend.FormatHelperTest do
  alias SlackLoggerBackend.FormatHelper

  use ExUnit.Case

  test "scrubber redacts secrets" do
    scrubber = {~r/(password|token|secret)(:\s+\")(.+?)(\")/, "\\1\\2--redacted--\\4"}
    Application.put_env(:slack_logger_backend, :scrubber, scrubber)

    message =
      %{
        level: "error",
        message:
          "username: \"user\", password: \"password\", access_token: \"token\", client_secret:  \"secret\""
      }
      |> FormatHelper.format_event()
      |> get_message()

    assert message ==
             "username: \"user\", password: \"--redacted--\", access_token: \"--redacted--\", client_secret:  \"--redacted--\""
  end

  defp get_message(message) do
    message
    |> Jason.decode()
    |> elem(1)
    |> Map.get("attachments")
    |> List.first()
    |> Map.get("pretext")
  end
end
