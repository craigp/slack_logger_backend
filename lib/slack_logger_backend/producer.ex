defmodule SlackLoggerBackend.Producer do
  @moduledoc """
  Produces logger events to be consumed and send to Slack.
  """
  use GenStage

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    {:producer, {:queue.new(), 0}}
  end

  @doc false
  def handle_cast({:add, event}, {queue, demand}) when demand > 0 do
    {:noreply, [event], {queue, demand - 1}}
  end

  @doc false
  def handle_cast({:add, event}, {queue, demand}) do
    {:noreply, [], {:queue.in(event, queue), demand}}
  end

  @doc false
  def handle_demand(incoming_demand, {queue, demand}) when incoming_demand > 0 do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  @doc """
  Adds a logger event to the queue for sending to Slack.
  """
  def add_event(event) do
    GenStage.cast(__MODULE__, {:add, event})
  end

  defp dispatch_events(queue, demand, events) when demand > 0 do
    case :queue.out(queue) do
      {:empty, queue} ->
        {:noreply, events, {queue, demand}}

      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])
    end
  end

  defp dispatch_events(queue, demand, events) do
    {:noreply, events, {queue, demand}}
  end
end
