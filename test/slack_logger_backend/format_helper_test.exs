defmodule SlackLoggerBackend.FormatHelperTest do
  alias SlackLoggerBackend.FormatHelper

  use ExUnit.Case

  test "scrubber redacts secrets" do
    scrubber = [
      {~r/(password|token|secret)(:\s+\")(.+?)(\")/, "\\1\\2--redacted--\\4"},
      {~r/(^\w+\s+\|\s+)/, ""},
      {~r/\#(PID|Reference)\<(\d|\.)+\>/, "#\\1\<\>"}
    ]

    message =
      "process_name | process_id: #PID<0.1234>, ref: #Reference<0.3570562526.2163015681.71254>, username: \"user\", password: \"password\", access_token: \"token\", client_secret:  \"secret\""
      |> FormatHelper.scrub(scrubber)

    assert message ==
             "process_id: #PID<>, ref: #Reference<>, username: \"user\", password: \"--redacted--\", access_token: \"--redacted--\", client_secret:  \"--redacted--\""
  end
end
