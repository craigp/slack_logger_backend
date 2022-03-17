defmodule SlackLoggerBackend.Logger do
  @moduledoc """
  The actual logger backend for sending logger events to Slack.
  """

  alias SlackLoggerBackend.Producer
  alias SlackLoggerBackend.FormatHelper

  @default_log_levels [:error]

  @doc false
  def init(__MODULE__) do
    {:ok, %{levels: []}}
  end

  def init({__MODULE__, levels}) when is_atom(levels) do
    {:ok, %{levels: [levels]}}
  end

  def init({__MODULE__, levels}) when is_list(levels) do
    {:ok, %{levels: levels}}
  end

  @doc false
  def handle_call(_request, state) do
    {:ok, state}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: []} = state) do
    levels =
      case get_env(:levels) do
        nil -> @default_log_levels
        levels -> levels
      end

    if level in levels do
      do_handle_event(level, message, detail)
    end

    {:ok, %{state | levels: levels}}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: levels} = state) do
    if level in levels do
      do_handle_event(level, message, detail)
    end

    {:ok, state}
  end

  @doc false
  def handle_event(:flush, state) do
    {:ok, state}
  end

  @doc false
  def handle_info(_message, state) do
    {:ok, state}
  end

  defp do_handle_event(level, message, detail) when is_list(detail) do
    detail
    |> Keyword.take([
      :application,
      :module,
      :function,
      :file,
      :line
    ])
    |> Enum.into(%{level: level, message: message})
    |> send_event()
  end

  defp do_handle_event(_level, _message, _detail) do
    :noop
  end

  defp send_event(event) do
    scrubber = get_env(:scrubber)

    message =
      event.message
      |> to_string()
      |> FormatHelper.scrub(scrubber)

    event
    |> Map.put(:message, message)
    |> Producer.add_event()
  end

  defp get_env(key, default \\ nil) do
    Application.get_env(:slack_logger_backend, key, default)
  end
end
