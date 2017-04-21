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

  def parse([%Token{value: value} | ts]) do
    {val, rest} = parse(ts)
    {[value | val], rest}
  end
end
