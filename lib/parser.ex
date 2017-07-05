defmodule Sammal.Parser do
  @moduledoc """
  A simple recursive parser for a Scheme-ish language.
  """
  alias Sammal.{Expr, SammalError}


  # TODO explore macros to clear up pattern matches?

  @typedoc """
  A form consists of a list of expressions.
  """
  @type form :: [Expr]

  @typedoc """
  All the parse_* functions adhere to the following pattern:
    {AST, tokens} -> {:ok, {new AST, remaining tokens}} | {:error, error struct}
  """
  @type cursor :: {ast :: [form], remaining :: [Expr]}


  @doc """
  Parser entrypoint.

  ## Example

    iex> {:ok, tokens} = Sammal.Tokenizer.tokenize("(define (x 10))")
    iex> {:ok, {[[define, [_var, _val]]], []}} = Sammal.Parser.parse(tokens)
    iex> define
    %Sammal.Expr{ctx: "(define (x 10))", lex: "define", line: 0, row: 1, val: :define}
  """
  @spec parse([Expr]) :: {:ok, cursor} | {:error, SammalError}
  def parse(tokens), do: parse_all_expressions({[], tokens})

  @doc """
  Parse all parenthesis-enclosed expressions.
  """
  @spec parse_all_expressions(cursor) :: {:ok, cursor} | {:error, SammalError}
  def parse_all_expressions({ast, []}), do: {:ok, {ast, []}}
  def parse_all_expressions({_ast, _tokens} = input) do
    case parse_next(input) do
      # TODO use helper
      {:ok, {val, rest}} ->
        parse_all_expressions({val, rest})
      {:error, error} ->
        {:error, error}
    end
  end

  # TODO
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
  @spec parse_expression(cursor) :: {:ok, cursor} | {:error, SammalError}
  def parse_expression({ast, [%Expr{lex: "("} = head | tokens]}) do
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
    {:error, SammalError.new(:unexpected, t, "(")}
  end

  @doc """
  Parse the next atom or expression.
  """
  @spec parse_next(cursor) :: {:ok, cursor} | {:error, SammalError}
  def parse_next({ast, tokens} = input) do
    # TODO instead of checking the first token, try parse_expression first and fallback to others? parser combinator-ish style
    case tokens do
      [%Expr{lex: "("} = head, %Expr{lex: ")"} | ts] ->
        {:ok, {ast ++ [%{head | lex: "()", val: []}], ts}}
      [%Expr{lex: "("} | _] ->
        parse_expression(input)
      [%Expr{lex: "'"} = expr | ts] ->
        # TODO use helper
        case parse_next({[], ts}) do
          {:ok, {val, rest}} ->
            {:ok, {ast ++ [[%{expr | val: :quote} | val]], rest}}
          {:error, error} ->
            {:error, error}
        end
      [%Expr{} = expr | rest] ->
        {:ok, {ast ++ [expr], rest}}
    end
  end

  @doc """
  Parse up to (and including) the given lexeme.
  """
  @spec parse_until(cursor, String.t) :: {:ok, cursor} | {:error, nil}
  def parse_until({_, []}, _), do: {:error, nil} # Error struct is formed higher up the call stack where context is available
  def parse_until({ast, [%Expr{lex: until} | rest]}, until), do: {:ok, {ast, rest}}
  def parse_until({_ast, _tokens} = input, until) do
    # TODO use helper
    case parse_next(input) do
      {:ok, val} -> parse_until(val, until)
      {:error, error} -> {:error, error}
    end
  end
end
