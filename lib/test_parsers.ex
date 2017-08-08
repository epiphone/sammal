defmodule Sammal.TestParsers do
  @moduledoc """
  Various parsers used for examples and tests.

  Parsers are defined here as opposed to defining them inline in test modules
  for a) readability, and b) because for recursive grammars we need
  self-referential functions and Elixir doesn't support self-referential
  anonymous (or inline) functions.
  """
  # import Sammal.ParserCombinators
  import Sammal.ParserCombinators.DefParser


  def test(), do: ambiguous_calc().([12, "+", 13, "*", 4], &(&1))

  def_parser any(parsers), do: fn (input, cont) ->
    for parser <- parsers, do: parser.(input, cont)
  end

  def bind(parser, f), do: fn (input, cont) ->
    parser.(input, fn (res) ->
      case res do
        {:ok, {value, rest}} ->
          f.(value).(rest, cont)
        err ->
          cont.(err)
      end
    end)
  end

  def seq(parsers, acc \\ [])
  def_parser seq([], acc), do: fn (input, cont) -> cont.({:ok, {acc, input}}) end
  def_parser seq([parser | rem_parsers], acc) do
    bind(fn (input, cont) -> parser.(input, cont) end, fn (value) ->
      seq(rem_parsers, acc ++ value)
    end)
  end

  def number(), do: fn
    ([head | rest], cont) when is_number(head) -> cont.({:ok, {[head], rest}})
    (input, cont) -> cont.({:error, input, "a number"})
  end

  def string(string), do: fn
    ([^string | rest], cont) -> cont.({:ok, {[string], rest}})
    (input, cont) -> cont.({:error, input, string})
  end

  def_parser memo_string(string), do: fn
    ([^string | rest], cont) -> cont.({:ok, {[string], rest}})
    (input, cont) -> cont.({:error, input, string})
  end

  def transform(parser, f), do: fn (input, cont) ->
    parser.(input, fn
      ({:ok, {val, rest}}) -> cont.({:ok, {f.(val), rest}})
      (err) -> cont.(err)
    end)
  end

  @doc """
  Parse a simple directly left-recursive grammar:

    E → E + number | number
  """
  def_parser left_recursive(), do: any([
    seq([left_recursive(), string("+"), number]),
    number
  ])

  @doc """
  Parse a simple ambiguous calculus grammar:

    E → E + E | E * E | E | number
  """
  def_parser ambiguous_calc(), do: any([
    transform(
      seq([ambiguous_calc(), string("+"), ambiguous_calc()]),
      &[&1]
    ),
    transform(
      seq([ambiguous_calc(), string("*"), ambiguous_calc()]),
      &[&1]
    ),
    ambiguous_calc(),
    number
  ])


  # TODO test https://en.wikipedia.org/wiki/Dangling_else
end
