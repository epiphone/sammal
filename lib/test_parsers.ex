defmodule Sammal.TestParsers do
  @moduledoc """
  Various parsers used for examples and tests.

  Parsers are defined here as opposed to defining them inline in test modules
  for a) readability, and b) because Elixir doesn't support self-referential
  anonymous (inline) functions which are required for some recursive parsers.
  """
  import Sammal.Memoization
  import Sammal.ParserCombinators


  def test(), do: cps_left_recursive().([12], &(&1))

  defcpsparser cps_any(parsers), do: fn (input, cont) ->
    for parser <- parsers, do: parser.(input, cont)
  end

  def cps_bind(parser, f), do: fn (input, cont) ->
    parser.(input, fn (res) ->
      case res do
        {:ok, {value, rest}} ->
          f.(value).(rest, cont)
        err ->
          cont.(err)
      end
    end)
  end

  def cps_seq(parsers, acc \\ [])
  defcpsparser cps_seq([], acc), do: fn (input, cont) -> cont.({:ok, {acc, input}}) end
  defcpsparser cps_seq([parser | rem_parsers], acc) do
    cps_bind(fn (input, cont) -> parser.(input, cont) end, fn (value) ->
      cps_seq(rem_parsers, acc ++ value)
    end)
  end

  def cps_number(), do: fn
    ([head | rest], cont) when is_number(head) -> cont.({:ok, {[head], rest}})
    (input, cont) -> cont.({:error, input, "a number"})
  end

  def cps_string(string), do: fn
    ([^string | rest], cont) -> cont.({:ok, {[string], rest}})
    (input, cont) -> cont.({:error, input, string})
  end

  defcpsparser memo_cps_string(string), do: fn
    ([^string | rest], cont) -> cont.({:ok, {[string], rest}})
    (input, cont) -> cont.({:error, input, string})
  end

  def cps_delay(parser_fn), do: fn (input, cont) ->
    parser = parser_fn.()
    parser.(input, cont)
  end

  @doc """
  Parse a simple directly left-recursive grammar:

    E → E + number | number
  """
  defcpsparser cps_left_recursive(), do: cps_any([
    cps_seq([cps_delay(&cps_left_recursive/0), cps_string("+"), cps_number]),
    cps_number
  ])
  # def left_recursive(), do: any([
  #   sequence([delay(&left_recursive/0), string("+"), number]),
  #   number
  # ])

  @doc """
  Parse a simple ambiguous calculus grammar:

    E → E + E | E * E | E | number
  """
  def ambiguous_calc(), do: any([
    sequence([delay(&ambiguous_calc/0), string("+"), delay(&ambiguous_calc/0)]),
    sequence([delay(&ambiguous_calc/0), string("*"), delay(&ambiguous_calc/0)]), # TODO fix not resolving all ambigous parsers
    delay(&ambiguous_calc/0),
    number
  ])

  defcpsparser cps_ambiguous_calc(), do: cps_any([
    cps_seq([cps_delay(&cps_ambiguous_calc/0), cps_string("+"), cps_delay(&cps_ambiguous_calc/0)]),
    cps_seq([cps_delay(&cps_ambiguous_calc/0), cps_string("*"), cps_delay(&cps_ambiguous_calc/0)]),
    cps_delay(&cps_ambiguous_calc/0),
    cps_number
  ])

  # TODO test https://en.wikipedia.org/wiki/Dangling_else
end
