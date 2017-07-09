defmodule Sammal.ParserV2 do
  @moduledoc """
  A parser for Sammal based on parser combinators.

  primitive   : number | atom | string
  form:       : '(' <expression>* ')'
  expression  : <primitive> | <form>
  sammal      : /^/ <expression>+ /$/
  """
  import Sammal.ParserCombinators
  alias Sammal.Expr


  @type result :: {value :: [Expr], remaining :: [Expr]}
  @type error :: atom
  @type parser :: (input :: [Expr] -> {:ok, result} | {:error, error})


  @spec token(any | (any -> boolean), error) :: parser
  def token(target, error \\ :unexpected)

  def token(target, error) when is_function(target) do
    fn ([%Expr{val: val} = head | rest]) ->
      if target.(val) do
        {:ok, {[head], rest}}
      else
        {:error, error}
      end
    end
  end

  def token(target, error), do: fn
    ([%Expr{val: ^target} = head | rest]) -> {:ok, {[head], rest}}
    (_) -> {:error, error}
  end

  def number(), do: token(&is_number/1)
  def string(), do: token(&is_binary/1)
  def symbol(), do: token(fn
    (val) when val in [:"(", :")"] -> false
    (val) -> is_atom(val)
  end)

  def primitive(), do: any([number, string, symbol])

  def expression(), do: either(
    between(token(:"("), many(delay(&expression/0)), token(:")")),
    primitive
  )
end
