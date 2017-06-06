defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.

  All the parse_* functions adhere to the following pattern:
    {AST, tokens} -> {:ok, {new AST, remaining tokens}} | {:error, error struct}
  """
  alias Sammal.{SammalError, Token}


  @doc """
  Parser entrypoint.

  ## Example

    iex> {:ok, tokens} = Sammal.Tokenizer.tokenize("(begin (define (x 10) (y 12)))")
    iex> Sammal.Parser.parse(tokens)
    {:ok, {[[:begin, [:define, [:x, 10], [:y, 12]]]], []}}
  """
  def parse(tokens), do: parse_all_expressions({[], tokens})

  @doc """
  Parse all parenthesis-enclosed expressions.
  """
  def parse_all_expressions({ast, []}), do: {:ok, {ast, []}}
  def parse_all_expressions({ast, tokens} = input) do
    case parse_expression(input) do
      # TODO use helper
      {:ok, {val, rest}} ->
        parse_all_expressions({val, rest})
      {:error, error} ->
        {:error, error}
    end
  end

  # input
  # |> first_parser
  # |> _combine(second_parser)

  # def pipe_parsers({ast, tokens} = input, parser) when is_function(parser) do
  #   case parser(input) do
  #     {:ok, {val, rest}} ->

  #   end
  # end

  @doc """
  Parse a single parenthesis-enclosed expression.
  """
  def parse_expression({ast, [%Token{lexeme: "("} = head | tokens]}) do
    case parse_until({[], tokens}, ")") do
      {:ok, {val, rest}} ->
        {:ok, {ast ++ [val], rest}}
        # TODO helper available?
      {:error, nil} ->
        {:error, SammalError.new(:unmatched_paren, head)}
      {:error, error} ->
        {:error, error}
    end
  end

  def parse_expression({_, [t | _]}) do
    {:error, SammalError.new(:unexpected_token, t, "(")}
  end

  @doc """
  Parse the next atom or expression.
  """
  def parse_next({ast, tokens} = input) do
    # TODO instead of checking the first token, try parse_expression first and fallback to others? parser combinator-ish style
    case tokens do
      [%Token{lexeme: "("} | _] ->
        parse_expression(input)
      [%Token{lexeme: "'"} | ts] ->
        # TODO use helper
        case parse_next({[], ts}) do
          {:ok, {val, rest}} ->
            {:ok, {ast ++ [[:quote | val]], rest}}
          {:error, error} ->
            {:error, error}
        end
      [%Token{value: value} | rest] ->
        {:ok, {ast ++ [value], rest}}
    end
  end

  @doc """
  Parse up to (and including) the given lexeme.
  """
  def parse_until({_, []}, _), do: {:error, nil} # Error struct is formed higher up the call stack where context is available
  def parse_until({ast, [%Token{lexeme: until} | rest]}, until), do: {:ok, {ast, rest}}
  def parse_until({ast, tokens} = input, until) do
    # TODO use helper
    case parse_next(input) do
      {:ok, val} -> parse_until(val, until)
      {:error, error} -> {:error, error}
    end
  end
end
