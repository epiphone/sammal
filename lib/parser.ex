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
    resp = tokens
    |> Stream.unfold(fn ts ->
      IO.inspect parse(ts), pretty: true
      case parse(ts) do
        {:end, rest} -> nil
        {val, rest} -> {{val, rest}, rest}
      end
    end)
    |> Enum.reduce({[], tokens}, fn {i, [_ | rest]}, {acc, _} ->
      {acc ++ [i], rest}
    end)
    IO.inspect {"resp", resp}, pretty: true
    resp
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
