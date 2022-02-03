defmodule SlackLoggerBackend.Pool do
  @moduledoc """
  A pool of workers for sending messages to Slack.
  """
  use Supervisor
  alias SlackLoggerBackend.PoolWorker

  @env_webhook "SLACK_LOGGER_WEBHOOK_URL"

  @doc false
  def start_link(pool_size) do
    Supervisor.start_link(__MODULE__, pool_size, name: __MODULE__)
  end

  def init(pool_size) do
    poolboy_config = [
      {:name, {:local, :message_pool}},
      {:worker_module, PoolWorker},
      {:size, pool_size},
      {:max_overflow, 0}
    ]

    children = [
      :poolboy.child_spec(:message_pool, poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]

    Supervisor.init(children, options)
  end

  @doc """
  Gets a message.
  """
  @spec post(String.t()) :: atom
  def post(json) do
    :poolboy.transaction(
      :message_pool,
      fn pid ->
        PoolWorker.post(pid, get_url(), json)
      end,
      :infinity
    )
  end

  defp get_url() do
    case System.get_env(@env_webhook) do
      nil -> Application.get_env(:slack_logger_backend, :slack_webhook, nil)
      url -> url
    end
  end
end
