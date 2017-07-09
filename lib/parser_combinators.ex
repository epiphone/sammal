defmodule Sammal.ParserCombinators do
  @moduledoc """
  Experimenting with parser combinators.
  TODO docs
  """
  @type token :: any
  @type result :: {value :: [token], remaining :: [token]}
  @type error :: atom

  @type parser :: ((input :: [token]) -> {:ok, result} | {:error, error})
  @type transformer :: (result -> result)

    # number   : /-?[0-9]+/ ;
    # operator : '+' | '-' | '*' | '/' ;
    # expr     : <number> | '(' <operator> <expr>+ ')' ;
    # lispy    : /^/ <operator> <expr>+ /$/ ;

  @spec symbol(String.t) :: parser
  def symbol(symbol), do: fn
    ([^symbol | rest]) -> {:ok, {[symbol], rest}}
    (_) -> {:error, :unexpected} # TODO: do errors need a type?
  end

  @spec both(parser, parser) :: parser
  def both(a, b), do: fn (input) ->
    with {:ok, {val_a, rest_a}} <- a.(input),
        {:ok, {val_b, rest_b}} <- b.(rest_a) do
      {:ok, {val_a ++ val_b, rest_b}}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec either(parser, parser) :: parser
  def either(a, b), do: fn (input) ->
    case a.(input) do
      {:ok, val} -> {:ok, val}
      _ -> b.(input)
    end
  end

  @spec many(parser) :: parser
  def many(parser), do: fn (input) -> _many(parser, [], input) end
  defp _many(parser, acc, []), do: {:ok, {acc, []}}
  defp _many(parser, acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        _many(parser, acc ++ value, rest)
      {:error, _} ->
        {:ok, {acc, input}}
    end
  end

  @spec skip(parser) :: parser
  def skip(parser), do: fn (input) ->
    case parser.(input) do
      {:ok, {_, rest}} ->
        {:ok, {[], rest}}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec any([parser]) :: parser
  def any([parser]), do: fn (input) -> parser.(input) end
  def any([parser | rest]) when length(rest) > 0, do: fn (input) ->
    case parser.(input) do
      {:ok, val} -> {:ok, val}
      {:error, _} -> any(rest).(input)
    end
  end

  @spec until(parser, parser) :: parser
  def until(parser, stop), do: fn (input) -> _until(parser, stop, [], input) end
  defp _until(_, _, acc, []), do: {:error, :unexpected} # TODO handle eof?
  defp _until(parser, stop, acc, input) do
    case stop.(input) do
      {:ok, _} ->
        {:ok, {acc, input}}
      {:error, _} ->
        case parser.(input) do
          {:ok, {value, rest}} ->
            _until(parser, stop, acc ++ value, rest)
          {:error, error} ->
            {:error, error}
        end
    end
  end

  @spec sequence([parser]) :: parser
  def sequence(parsers) when length(parsers) > 0, do: fn (input) ->
    _sequence(parsers, [], input)
  end

  defp _sequence(_, _, []), do: {:error, :unexpected} # TODO handle eof?

  defp _sequence([parser], acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        {:ok, {acc ++ value, rest}}
      {:error, error} ->
        {:error, error}
    end
  end

  defp _sequence([parser | rem_parsers], acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        _sequence(rem_parsers, acc ++ value, rest)
      {:error, error} ->
        {:error, error}
    end
  end

  @spec between(parser, parser, parser) :: parser
  def between(a, b, c), do: sequence([skip(a), b, skip(c)])

  @spec transform(transformer, parser) :: parser
  def transform(f, parser), do: fn (input) ->
    case parser.(input) do
      {:ok, {value, rest}} ->
        {:ok, {f.(value), rest}}
      {:error, error} ->
        {:error, error}
    end
  end

  @moduledoc """
  Delay parser evaluation to handle infinite loops in self-referential parsers.
  """
  @spec delay((() -> parser)) :: parser
  def delay(parser_func), do: fn (input) ->
    parser = parser_func.()
    parser.(input)
  end
end
