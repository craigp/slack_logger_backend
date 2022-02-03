defimpl Poison.Encoder, for: List do
  alias Poison.{Encoder, Pretty}

  use Pretty

  @compile :inline
  @compile :inline_list_funcs

  def encode([], _options), do: "[]"

  def encode(list, options) do
    encode(list, pretty(options), options)
  end

  def encode([head | string], pretty, options) when is_binary(string) do
    encode([head, string], pretty, options)
  end

  def encode(list, false, options) do
    [?[, tl(:lists.foldr(&[?,, Encoder.encode(&1, options) | &2], [], list)), ?]]
  end

  def encode(list, true, options) do
    indent = indent(options)
    offset = offset(options) + indent
    options = offset(options, offset)

    [
      "[\n",
      tl(:lists.foldr(&[",\n", spaces(offset), Encoder.encode(&1, options) | &2], [], list)),
      ?\n,
      spaces(offset - indent),
      ?]
    ]
  end
end
