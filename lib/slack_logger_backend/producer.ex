defmodule SlackLoggerBackend.Producer do
  @moduledoc """
  Produces logger events to be consumed and send to Slack.
  """
  use GenStage

  @doc false
  def start_link([]) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    debounce = Application.get_env(:slack_logger_backend, :debounce_seconds, nil)

    # {:producer, {:queue.new(), 0}}
    state = %{
      event_map: %{},
      debounce: debounce,
      demand: 0,
      queue: :queue.new()
    }

    {:producer, state}
  end

  # @doc false
  # def handle_cast({:add, event}, {queue, demand}) when demand > 0 do
  #   {:noreply, [event], {queue, demand - 1}}
  # end

  # @doc false
  # def handle_cast({:add, event}, {queue, demand}) do
  #   {:noreply, [], {:queue.in(event, queue), demand}}
  # end

  @doc false
  def handle_cast({:add, event}, state) do
    time = System.monotonic_time(:second)

    state =
      if Map.has_key?(state.event_map, event) do
        # handle duplicate event
        count = Map.get(state.event_map, event)
        event_map = Map.put(state.event_map, event, count + 1)
        %{state | event_map: event_map}
      else
        # handle new event
        queue = :queue.in({time, event}, state.queue)
        event_map = Map.put(state.event_map, event, 1)
        %{state | event_map: event_map, queue: queue}
      end

    dispatch_events(state, [])
  end

  @doc false
  def handle_demand(incoming_demand, state = %{demand: demand}) when incoming_demand > 0 do
    state = %{state | demand: incoming_demand + demand}
    dispatch_events(state, [])
  end

  @doc """
  Adds a logger event to the queue for sending to Slack.
  """
  def add_event(event) do
    GenStage.cast(__MODULE__, {:add, event})
  end

  defp dispatch_events(state = %{demand: demand}, events) when demand > 0 do
    case :queue.out(state.queue) do
      {:empty, _queue} ->
        {:noreply, events, state}

      {{:value, {time, event}}, queue} ->
        if is_nil(state.debounce) or state.debounce > System.monotonic_time(:second) - time do
          count = Map.get(state.event_map, event)
          event_map = Map.delete(state.event_map, event)
          state = %{state | demand: demand - 1, queue: queue, event_map: event_map}
          dispatch_events(state, [{count, event} | events])
        else
          {:noreply, events, state}
        end
    end
  end

  defp dispatch_events(state, events) do
    {:noreply, events, state}
  end
end
