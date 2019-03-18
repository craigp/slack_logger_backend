defmodule SlackLoggerBackend.PoolWorker do
  @moduledoc """
  A message pool worker.
  """

  use GenServer

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({:post, url, json}, _from, worker_state) do
    result = HTTPoison.post(url, json)
    {:reply, result, worker_state}
  end

  @doc """
  Gets a message.
  """
  @spec post(pid, String.t(), String.t()) :: atom
  def post(pid, url, json) do
    GenServer.call(pid, {:post, url, json}, :infinity)
  end
end
