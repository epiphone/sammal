defmodule Sammal.ParserCombinators do
  @moduledoc """
  Experimenting with parser combinators.
  TODO docs
  TODO handle errors: :eof/1, :unexpected/2, :unexpected_eof/1
  """
  @type token :: any
  @type result :: {value :: [token], remaining :: [token]}
  @type error :: atom

  @type parser :: ((input :: [token]) -> {:ok, result} | {:error, error})
  @type transformer :: ([token] -> [token])

    # number   : /-?[0-9]+/ ;
    # operator : '+' | '-' | '*' | '/' ;
    # expr     : <number> | '(' <operator> <expr>+ ')' ;
    # lispy    : /^/ <operator> <expr>+ /$/ ;

  @spec symbol(String.t) :: parser
  def symbol(symbol), do: fn
    ([^symbol | rest]) -> {:ok, {[symbol], rest}}
    ([head | _]) -> {:error, {:unexpected, head, symbol}}
    ([]) -> {:error, {:unexpected_eof, symbol}}
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

  @doc "Parse end of file."
  @spec eof() :: parser
  def eof(), do: fn
    ([]) -> {:ok, {[], []}}
    ([head | _]) -> {:error, {:eof, head}}
  end

  @spec transform(transformer, parser) :: parser
  def transform(f, parser), do: fn (input) ->
    case parser.(input) do
      {:ok, {value, rest}} ->
        {:ok, {f.(value), rest}}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Delay parser evaluation to prevent infinite loops in self-referential parsers.
  """
  @spec delay((() -> parser)) :: parser
  def delay(parser_func), do: fn (input) ->
    parser = parser_func.()
    parser.(input)
  end

  @doc """
  Turn parser failure into a fatal exception.
  """
  @spec required(parser) :: parser
  def required(parser), do: fn (input) ->
    case parser.(input) do
      {:ok, val} -> {:ok, val}
      {:error, error} -> throw error
    end
  end

  @doc """
  Wrap parser result into a list.
  """
  @spec wrap(parser) :: parser
  def wrap(parser), do: transform(fn (val) -> [val] end, parser)
end
