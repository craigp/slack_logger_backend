ExUnit.start()

defmodule SlackLoggerBackendTest do
  use ExUnit.Case
  require Logger

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}/hook"
    Application.put_env(SlackLoggerBackend, :slack, url: url)
    System.put_env("SLACK_LOGGER_WEBHOOK_URL", url)
    {:ok, _} = Logger.add_backend(SlackLoggerBackend.Logger, flush: true)
    Application.put_env(SlackLoggerBackend, :levels, [:debug, :info, :warn, :error])
    SlackLoggerBackend.start(nil, nil)

    on_exit(fn ->
      Logger.remove_backend(SlackLoggerBackend.Logger, flush: true)
      SlackLoggerBackend.stop(nil)
    end)

    {:ok, %{bypass: bypass}}
  end

  test "posts the error to the Slack incoming webhook", %{bypass: bypass} do
    Application.put_env(SlackLoggerBackend, :levels, [:error])

    on_exit(fn ->
      Application.put_env(SlackLoggerBackend, :levels, [:debug, :info, :warn, :error])
    end)

    Bypass.expect(bypass, fn conn ->
      assert "/hook" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, _} = Plug.Conn.read_body(conn)

      assert body ==
               "{\"attachments\":[{\"pretext\":\"This error should be logged to Slack\",\"fields\":[{\"value\":\"error\",\"title\":\"Level\",\"short\":true},{\"value\":null,\"title\":\"Application\",\"short\":true},{\"value\":\"Elixir.SlackLoggerBackendTest\",\"title\":\"Module\",\"short\":true},{\"value\":\"test posts the error to the Slack incoming webhook/1\",\"title\":\"Function\",\"short\":true},{\"value\":\"/home/hans/work/elixir-utils/slack_logger_backend/test/slack_logger_backend_test.exs\",\"title\":\"File\",\"short\":true},{\"value\":42,\"title\":\"Line\",\"short\":true}],\"fallback\":\"An error level event has occurred: This error should be logged to Slack\"}]}"

      Plug.Conn.resp(conn, 200, "ok")
    end)

    Logger.error("This error should be logged to Slack")
    Logger.flush()
    :timer.sleep(500)
  end

  test "posts the error to the Slack incoming webhook no meta data", %{bypass: bypass} do
    Application.put_env(SlackLoggerBackend, :levels, [:error])

    on_exit(fn ->
      Application.put_env(SlackLoggerBackend, :levels, [:debug, :info, :warn, :error])
    end)

    Bypass.expect(bypass, fn conn ->
      assert "/hook" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, _} = Plug.Conn.read_body(conn)

      assert body ==
               "{\"attachments\":[{\"pretext\":\"This error should be logged to Slack\",\"fallback\":\"An error level event has occurred: This error should be logged to Slack\"}]}"

      Plug.Conn.resp(conn, 200, "ok")
    end)

    Logger.bare_log(:error, "This error should be logged to Slack")
    Logger.flush()
    :timer.sleep(500)
  end

  test "doesn't post a debug message to Slack if the level is not set", %{bypass: bypass} do
    Application.put_env(SlackLoggerBackend, :levels, [:info])

    on_exit(fn ->
      Application.put_env(SlackLoggerBackend, :levels, [:debug, :info, :warn, :error])
    end)

    Bypass.expect(bypass, fn _conn ->
      flunk("Slack should not have been notified")
    end)

    Bypass.pass(bypass)

    Logger.error("This error should not be logged to Slack")
    Logger.flush()
    :timer.sleep(500)
  end
end
