defmodule SlackLoggerBackend.Logger do
  @moduledoc """
  The actual logger backend for sending logger events to Slack.
  """

  alias SlackLoggerBackend.Producer
  alias SlackLoggerBackend.FormatHelper

  @default_log_levels [:error]

  @doc false
  def init(__MODULE__), do: do_init([])
  def init({__MODULE__, level}) when is_atom(level), do: do_init([level])
  def init({__MODULE__, levels}) when is_list(levels), do: do_init(levels)

  defp do_init(levels) do
    levels =
      case levels do
        [] -> get_env(:levels, @default_log_levels)
        levels -> levels
      end

    {ignore_messages, ignore_events} = Enum.split_with(get_env(:ignore, []), &is_binary/1)

    ignore_messages = Enum.map(ignore_messages, &String.replace(&1, ~r/\s+/, " "))

    opts = [
      ignore_messages: ignore_messages,
      ignore_events: ignore_events
    ]

    {:ok, %{levels: levels, opts: opts}}
  end

  @doc false
  def handle_call(_request, state), do: {:ok, state}

  @doc false
  def handle_info(_message, state), do: {:ok, state}

  @doc false
  def handle_event(:flush, state), do: {:ok, state}

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: levels} = state) do
    app = detail[:application]

    if level in levels and app != :slack_logger_backend do
      do_handle_event(level, message, detail, state.opts)
    end

    {:ok, state}
  end

  defp do_handle_event(level, message, detail, opts) when is_list(detail) do
    detail
    |> Keyword.take([
      :application,
      :module,
      :function,
      :file,
      :line
    ])
    |> Enum.into(%{level: level, message: message})
    |> send_event(opts)
  end

  defp do_handle_event(_level, _message, _detail, _opts) do
    :noop
  end

  defp send_event(event, opts) do
    scrubber = get_env(:scrubber)

    message =
      event.message
      |> to_string()
      |> FormatHelper.scrub(scrubber)
      |> String.trim()

    unless should_ignore(event, message, opts) do
      event
      |> Map.put(:message, message)
      |> Producer.add_event()
    end
  end

  defp should_ignore(event, message, opts) do
    ignore_messages = opts[:ignore_messages]
    ignore_events = opts[:ignore_events]
    compare_message = String.replace(message, ~r/\s+/, " ")

    # ignore if any ignore entry matches
    ignore_event =
      Enum.any?(
        ignore_events,
        # only ignore if all keywords in ignore entry match
        &Enum.all?(&1, fn {key, value} -> event[key] == value end)
      )

    ignore_event or Enum.member?(ignore_messages, compare_message)
  end

  defp get_env(key, default \\ nil) do
    Application.get_env(:slack_logger_backend, key, default)
  end
end
