defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for Lisp.
  """

  @doc ~S"""
  Parses a list of tokens into an AST.

  Remainder of the parsing operation is included in the return value:
  [tokens] -> {AST, [remaining tokens]}

  ## Example

    iex> Sammal.Parser.parse ~w/( begin ( define ( x 10 ) ( y 12 ) ) )/
    {[:begin, [:define, [:x, 10], [:y, 12]]], []}
  """
  def parse(["(" | tokens]) do
    exp =
    tokens
    |> Stream.unfold(fn [")" | _] -> nil;
                        ts ->
                          {exp, rest} = parse(ts)
                          {{exp, rest}, rest}
                     end)
    |> Enum.to_list

    remainder = List.last(exp) |> elem(1)
    expression = Enum.map(exp, fn {v, _} -> v end)
    case remainder do
      [")" | rem] -> {expression, rem}
      _ -> {expression, remainder}
    end
  end

  def parse([t | ts]), do: {symbol(t), ts}

  def symbol(token) when is_binary(token) do
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
