defmodule SlackLoggerBackend.Pool do
  @moduledoc """
  A pool of workers for sending messages to Slack.
  """
  use Supervisor
  alias SlackLoggerBackend.PoolWorker

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
  @spec post(String.t(), String.t()) :: atom
  def post(url, json) do
    :poolboy.transaction(
      :message_pool,
      fn pid ->
        PoolWorker.post(pid, url, json)
      end,
      :infinity
    )
  end
end
