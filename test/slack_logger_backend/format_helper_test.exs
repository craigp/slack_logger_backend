defmodule SlackLoggerBackend.FormatHelperTest do
  alias SlackLoggerBackend.FormatHelper

  use ExUnit.Case

  test "scrubber redacts secrets" do
    scrubber = [
      {~r/(password|token|secret)(:\s+\")(.+?)(\")/, "\\1\\2--redacted--\\4"},
      {~r/(^\w+\s+\|\s+)/, ""},
    ]

    message =
      "process_id | username: \"user\", password: \"password\", access_token: \"token\", client_secret:  \"secret\""
      |> FormatHelper.scrub(scrubber)

    assert message ==
             "username: \"user\", password: \"--redacted--\", access_token: \"--redacted--\", client_secret:  \"--redacted--\""
  end
end
