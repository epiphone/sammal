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
  @type error :: atom
  @type parser :: (input :: [Expr] -> {:ok, result} | {:error, error})


  @doc "Parse a `Sammal.Expr` struct that matches a given value or predicate."
  @spec token(any | (any -> boolean), error) :: parser
  def token(value_or_predicate, error \\ :unexpected)

  def token(predicate, error) when is_function(predicate) do
    fn ([%Expr{val: val} = head | rest]) ->
      if predicate.(val) do
        {:ok, {[head], rest}}
      else
        {:error, error}
      end
    end
  end

  def token(value, error), do: fn
    ([%Expr{val: ^value} = head | rest]) -> {:ok, {[head], rest}}
    (_) -> {:error, error}
  end

  @doc "Parse a number."
  @spec number :: parser
  def number(), do: token(&is_number/1)

  @doc "Parse a string."
  @spec string :: parser
  def string(), do: token(&is_binary/1)

  @doc "Parse a symbol."
  @spec symbol :: parser
  def symbol(), do: token(fn
    (val) when val in [:"(", :")"] -> false
    (val) -> is_atom(val)
  end)

  @doc "Parse a primitive expression."
  @spec primitive :: parser
  def primitive(), do: any([number, string, symbol])

  @doc "Parse an expression - either a form or a primitive."
  @spec expression :: parser
  def expression(), do: any([quoted, form, primitive])

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
  def sammal(), do: both(many(expression), eof)
end
