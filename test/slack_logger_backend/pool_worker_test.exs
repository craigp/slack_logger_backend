ExUnit.start()

defmodule SlackLoggerBackend.PoolWorkerTest do
  use ExUnit.Case
  alias SlackLoggerBackend.PoolWorker

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}/hook"
    Application.put_env(:slack_logger_backend, :slack_webhook, url)
    {:ok, %{bypass: bypass}}
  end

  test "posts the error to the Slack incoming webhook", %{
    bypass: bypass
  } do
    Bypass.expect(bypass, fn conn ->
      assert "/hook" == conn.request_path
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, "ok")
    end)

    {:ok, pid} = PoolWorker.start_link([])
    {:ok, _} = PoolWorker.post(pid, "test")
  end
end
