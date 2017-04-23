defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.
  """
  alias Sammal.{SammalError, Token}


  @doc ~S"""
  Parse a list of tokens into an AST.

  Remainder of the parsing operation is included in the return value:
  [tokens] -> {AST, [remaining tokens]}

  ## Example

    iex> Sammal.Tokenizer.tokenize("(begin (define (x 10) (y 12)))") |> elem(0) |> Sammal.Parser.parse
    {[[:begin, [:define, [:x, 10], [:y, 12]]]], [], []}
  """
  def parse([]), do: {[], [], []}
  def parse([%Token{lexeme: ")"} | ts]), do: {[], ts, []}
  def parse(ts) do
    {val, rest, err} = parse_next(ts)
    {val2, rest2, err2} = parse(rest)
    {val ++ val2, rest2, err ++ err2}
  end

  @doc """
  Parse a single parenthesis-enclosed expression.
  """
  def parse_expression([%Token{lexeme: "("}, %Token{lexeme: ")"} | ts]), do: {[], ts, []}
  def parse_expression([%Token{lexeme: "("} = t | []]) do
    {[], [], [%SammalError{token: t, type: :unexpected_token, expected: "EOF"}]}
  end
  def parse_expression([%Token{lexeme: "("} | ts]) do
    {val, rest, err} = parse_next(ts)
    if rest == [] do
      {val, [], err ++ [%SammalError{token: hd(ts), type: :unexpected_token, expected: ")"}]}
    else
      {val2, rest2, err2} = parse(rest)
      {val ++ val2, rest2, err ++ err2}
    end
  end

  def parse_expression([t | ts] = tokens) do
    {[], tokens, [%SammalError{token: t, type: :unexpected_token, expected: "("}]}
  end

  @doc """
  Parse a single token.
  """
  def parse_next([%Token{lexeme: "("} | ts]) do
     {val, rest, err} = parse(ts)
     {[val], rest, err}
  end

  def parse_next([%Token{lexeme: "'"} | ts]) do
    {val, rest, err} = parse_next(ts)
    {[[:quote | val]], rest, err}
  end

  def parse_next([%Token{value: value} | ts]) do
    {[value], ts, []}
  end
end
