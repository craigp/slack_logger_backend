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
    url = get_url()

    if is_binary(url) do
      result = HTTPoison.post(url, json)
      {:reply, result, worker_state}
    else
      {:reply, :no_url, worker_state}
    end
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
end
