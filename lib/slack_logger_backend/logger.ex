defmodule SlackLoggerBackend.Logger do

  @moduledoc """
  The actual logger backend for sending logger events to Slack.
  """

  use GenEvent
  alias SlackLoggerBackend.Producer

  @env_webhook "SLACK_LOGGER_WEBHOOK_URL"
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
    levels = case get_env(:levels) do
      nil ->
        @default_log_levels
      levels ->
        levels
    end
    if level in levels do
      handle_event(level, message, detail)
    end
    {:ok, %{state | levels: levels}}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: levels} = state) do
    if level in levels do
      handle_event(level, message, detail)
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

  defp get_url do
    case System.get_env(@env_webhook) do
      nil ->
        get_env(:slack)[:url]
      url ->
        url
    end
  end

  defp handle_event(level, message, meta) do
    application = Keyword.get(meta, :application)
    module = Keyword.get(meta, :module)
    function = Keyword.get(meta, :function)
    file = Keyword.get(meta, :file)
    line = Keyword.get(meta, :line)

    {level, message, module, function, file, line}
    |> send_event
  end

  defp send_event(event) do
    Producer.add_event({get_url(), event})
  end

  defp get_env(key, default \\ nil) do
    Application.get_env(SlackLoggerBackend, key, Application.get_env(:slack_logger_backend, key, default))
  end

end
