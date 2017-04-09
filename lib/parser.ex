defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.
  """

  @doc ~S"""
  Parses a list of tokens into an AST.

  Remainder of the parsing operation is included in the return value:
  [tokens] -> {AST, [remaining tokens]}

  ## Example

    iex> Sammal.Parser.parse ~w/( begin ( define ( x 10 ) ( y 12 ) ) )/
    {[[:begin, [:define, [:x, 10], [:y, 12]]]], []}
  """
  def parse([]), do: {[], []}
  def parse([")" | ts]), do: {[], ts}

  def parse(["(" | ts]) do
    {val, rest} = parse(ts)
    {val2, rest2} = parse(rest)
    {[val | val2], rest2}
  end

  def parse([t | ts]) do
    {val, rest} = parse(ts)
    {[parse_one(t) | val], rest}
  end


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
