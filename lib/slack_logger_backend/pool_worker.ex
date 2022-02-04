defmodule SlackLoggerBackend.PoolWorker do
  @moduledoc """
  A message pool worker.
  """

  use GenServer

  @env_webhook "SLACK_LOGGER_WEBHOOK_URL"

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({:post, json}, _from, worker_state) do
    result = HTTPoison.post(get_url(), json)
    {:reply, result, worker_state}
  end

  @doc """
  Gets a message.
  """
  @spec post(pid, String.t()) :: atom
  def post(pid, json) do
    GenServer.call(pid, {:post, json}, :infinity)
  end

  defp get_url() do
    case System.get_env(@env_webhook) do
      nil -> Application.get_env(:slack_logger_backend, :slack_webhook, nil)
      url -> url
    end
  end

  defimpl Inspect, for: HTTPoison.Response do
    def inspect(response, opts) do
      {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

      # check if PoolWorker is in the stack trace
      stacktrace
      |> Enum.any?(fn call -> elem(call, 0) == SlackLoggerBackend.PoolWorker end)
      |> if do
        # hide the webhook if it is
        %{response | request_url: "--hidden--", request: "--hidden--"}
      else
        response
      end
      |> Inspect.Any.inspect(opts)
    end
  end
end
