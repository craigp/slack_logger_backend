import Config

path = __DIR__ |> Path.expand |> Path.join("#{Mix.env}.exs")
if File.exists?(path), do: import_config "#{Mix.env}.exs"
