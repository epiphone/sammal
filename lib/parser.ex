defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.
  """

  def parse_expression(["(" | ts]) do
    {val, rest} = parse_expression(ts)
    {val2, rest2} = parse_expression(rest)
    {[val | val2], rest2}
  end
  def parse_expression([]) do
    {[], []}
  end

  def parse_expression([")" | ts]) do
    {[], ts}
  end
  def parse_expression([t | ts]) do
    {val, rest} = parse_expression(ts)
    {[parse_one(t) | val], rest}
  end

  def parse_one2([t | ts]) do
    {parse_one(t), ts}
  end

  @doc ~S"""
  Parses a list of tokens into an AST.

  Remainder of the parsing operation is included in the return value:
  [tokens] -> {AST, [remaining tokens]}

  ## Example

    iex> Sammal.Parser.parse ~w/( begin ( define ( x 10 ) ( y 12 ) ) )/
    {[:begin, [:define, [:x, 10], [:y, 12]]], []}
  """
  def parse(["(" | tokens]) do
    tokens
    |> Stream.unfold(fn ts ->
      case parse(ts) do
        {:end, rest} -> nil
        {val, rest} -> {{val, rest}, rest}
      end
    end)
    |> Enum.reduce({[], tokens}, fn {i, [_ | rest]}, {acc, _} ->
      {acc ++ [i], rest}
    end)
  end

  def parse([")" | ts]), do: {:end, ts}

  def parse([t | ts]), do: {parse_one(t), ts}

  @doc ~S"""
  Given a token, returns a matching raw data type.

  ## Example

    iex> Sammal.Parser.parse_one("12")
    12

    iex> Sammal.Parser.parse_one("12.12")
    12.12
  """
  def parse_one(token) when is_binary(token) do
    case Integer.parse(token) do
      {val, ""} -> val
      :error -> String.to_atom(token)
      {val, _} -> case Float.parse(token) do
        {val, ""} -> val
        _ -> String.to_atom(token)
      end
    end
  end
end
