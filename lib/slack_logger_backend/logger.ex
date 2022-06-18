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

    ignore =
      get_env(:ignore, [])
      |> Enum.map(&String.replace(&1, ~r/\s+/, " "))

    opts = [ignore: ignore]
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
    if level in levels do
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
    ignore_list = opts[:ignore] || []

    message =
      event.message
      |> to_string()
      |> FormatHelper.scrub(scrubber)
      |> String.trim()

    compare_message = String.replace(message, ~r/\s+/, " ")

    unless Enum.member?(ignore_list, compare_message) do
      event
      |> Map.put(:message, message)
      |> Producer.add_event()
    end
  end

  defp get_env(key, default \\ nil) do
    Application.get_env(:slack_logger_backend, key, default)
  end
end
