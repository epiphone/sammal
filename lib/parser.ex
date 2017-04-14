defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.
  """
  alias Sammal.Token

  @doc ~S"""
  Parses a list of tokens into an AST.

  Remainder of the parsing operation is included in the return value:
  [tokens] -> {AST, [remaining tokens]}

  ## Example

    iex> Sammal.Tokenizer.tokenize("(begin (define (x 10) (y 12)))") |> Sammal.Parser.parse
    {[[:begin, [:define, [:x, 10], [:y, 12]]]], []}
  """
  def parse([]), do: {[], []}
  def parse([%Token{lexeme: ")"} | ts]), do: {[], ts}

  def parse([%Token{lexeme: "("} | ts]) do
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

    iex> Sammal.Parser.parse_one(%Sammal.Token{lexeme: "12"})
    12

    iex> Sammal.Parser.parse_one(%Sammal.Token{lexeme: "12.12"})
    12.12
  """
  def parse_one(%Token{lexeme: lexeme}) do
    case Integer.parse(lexeme) do
      {val, ""} -> val
      :error -> String.to_atom(lexeme)
      {val, _} -> case Float.parse(lexeme) do
        {val, ""} -> val
        _ -> String.to_atom(lexeme)
      end
    end
  end
end
