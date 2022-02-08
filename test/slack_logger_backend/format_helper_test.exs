defmodule SlackLoggerBackend.FormatHelperTest do
  alias SlackLoggerBackend.FormatHelper

  use ExUnit.Case

  test "scrubber redacts secrets" do
    scrubber = {~r/(password: \")(.+)(\")/, "\\1--redadacted--\\3"}
    Application.put_env(:slack_logger_backend, :scrubber, scrubber)

    message =
      %{level: "error", message: "username: \"user\",  password: \"password\""}
      |> FormatHelper.format_event()
      |> get_message()

    assert message == "username: \"user\",  password: \"--redadacted--\""
  end

  defp get_message(message) do
    message
    |> Poison.decode()
    |> elem(1)
    |> Map.get("attachments")
    |> List.first()
    |> Map.get("pretext")
  end
end
