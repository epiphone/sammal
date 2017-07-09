defmodule Sammal.ParserV2 do
  @moduledoc """
  A parser for Sammal based on parser combinators.

  ## Grammar

  ```
  primitive   : number | symbol | string
  form:       : ( expression* )
  expression  : quoted | primitive | form
  quoted      : ' expression
  sammal      : expression+
  ```
  """
  import Sammal.ParserCombinators
  alias Sammal.Expr


  @type result :: {value :: [Expr], remaining :: [Expr]}
  @type error :: {label :: atom, context :: Expr} | {:eof, nil}
  @type parser :: (input :: [Expr] -> {:ok, result} | {:error, error})


  @doc "Parse a `Sammal.Expr` struct that matches given value or predicate."
  @spec token(any | (any -> boolean)) :: parser
  def token(value_or_predicate)

  def token(predicate) when is_function(predicate), do: fn
    ([%Expr{val: val} = head | rest] = input) ->
      if predicate.(val) do
        {:ok, {[head], rest}}
      else
        {:error, input, nil}
      end
    ([]) -> {:error, [], nil}
  end

  def token(value), do: fn
    ([%Expr{val: ^value} = head | rest]) -> {:ok, {[head], rest}}
    input -> {:error, input, value}
  end

  @doc "Parse a number."
  @spec number :: parser
  def number(), do: expect(token(&is_number/1), "a number")

  @doc "Parse a string."
  @spec string :: parser
  def string(), do: expect(token(&is_binary/1), "a string")

  @doc "Parse a symbol."
  @spec symbol :: parser
  def symbol(), do: expect(token(fn
    (val) when val in [:"(", :")"] -> false
    (val) -> is_atom(val)
  end), "a symbol")

  @doc "Parse a primitive expression."
  @spec primitive :: parser
  def primitive(), do: describe(any([number, string, symbol]), "primitive")

  @doc "Parse an expression - either a form or a primitive."
  @spec expression :: parser
  def expression(), do: describe(any([quoted, form, primitive]), "expression")

  @doc "Parse and extend a quoted expression."
  @spec quoted :: parser
  def quoted() do
    parser = both(token(:"'"), delay(&expression/0))
    extend_quote = fn ([quot | expr]) -> [[%{quot | val: :quote} | expr]] end
    transform(extend_quote, parser)
  end

  @doc "Parse parenthesis-enclosed forms."
  @spec form :: parser
  def form(), do: wrap(between(token(:"("), many(delay(&expression/0)), token(:")")))

  @doc "Parse a Sammal program."
  @spec sammal :: parser
  # def sammal(), do: both(many(expression), eof)
  def sammal(), do: until(expression, eof)
  # def sammal(), do: many(required(expression))
end
