defmodule Sammal.ParserCombinators do
  @moduledoc """
  Basic parser combinator building blocks.

  Use these to compose your own grammar.
  """
  @type token :: any
  @type result :: {value :: [token], remaining :: [token]}
  @type error :: atom

  @type parser :: ((input :: [token]) -> {:ok, result} | {:error, remaining :: [token]})
  @type transformer :: ([token] -> [token])

    # number   : /-?[0-9]+/ ;
    # operator : '+' | '-' | '*' | '/' ;
    # expr     : <number> | '(' <operator> <expr>+ ')' ;
    # lispy    : /^/ <operator> <expr>+ /$/ ;

  @doc """
  Parse given string.
  """
  @spec string(String.t) :: parser
  def string(string), do: fn
    ([^string | rest]) -> {:ok, {[string], rest}}
    input -> {:error, input, string}
  end

  @spec number() :: parser
  def number(), do: fn
    ([head | rest]) when is_number(head) -> {:ok, {[head], rest}}
    input -> {:error, input, "a number"}
  end

  # TODO regexp parser

  @doc """
  Override parser's expected value that is shown in parse errors.

  ## Examples

      iex> parser = Sammal.ParserCombinators.string("x")
      iex> parser.(["y"])
      {:error, ["y"], "x"}
      iex> Sammal.ParserCombinators.describe(parser, "something else").(["y"])
      {:error, ["y"], "something else"}
  """
  @spec describe(parser, any) :: parser
  def describe(parser, expected), do: fn (input) ->
    case parser.(input) do
      {:ok, value} ->
        {:ok, value}
      {:error, rem, _} when length(rem) == length(input) ->
        {:error, rem, expected}
      {:error, rem, exp} ->
        {:error, rem, {expected, [exp]}} # TODO always handle leaf nodes with root for context
      {:error, errs} when is_list(errs) ->
        {min_rem, _} = Enum.min_by(errs, fn ({rem, _}) -> length(rem) end)
        leaf_exps =
          errs
          |> Enum.filter(fn ({rem, _}) -> length(rem) == length(min_rem) end)
          |> Enum.map(fn ({_, exp}) -> exp end)

        {:error, min_rem, {expected, leaf_exps}}
    end
  end

  @spec both(parser, parser) :: parser
  def both(a, b), do: sequence([a, b])

  @spec either(parser, parser) :: parser
  def either(a, b), do: any([a, b])

  @spec many(parser) :: parser
  def many(parser), do: fn (input) -> _many(parser, [], input) end
  defp _many(parser, acc, []), do: {:ok, {acc, []}}
  defp _many(parser, acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        _many(parser, acc ++ value, rest)
      _err ->
        {:ok, {acc, input}}
    end
  end

  @spec many1(parser) :: parser
  def many1(parser), do: both(parser, many(parser))

  @spec skip(parser) :: parser
  def skip(parser), do: fn (input) ->
    case parser.(input) do
      {:ok, {_, rest}} -> {:ok, {[], rest}}
      err -> err
    end
  end

  @spec any([parser]) :: parser
  def any([], errors), do: fn (_) -> {:error, errors} end
  def any([parser | rest], errors \\ []), do: fn (input) ->
    case parser.(input) do
      {:ok, val} ->
        {:ok, val}
      {:error, rem, exp} ->
        any(rest, [{rem, exp} | errors]).(input)
    end
  end
    # TODO warn about ambiguity or memoize? (profile)
    # TODO parallelize?
    # case parser.(input) do
    #   {:ok, val} ->
    #     {:ok, val}
    #   {:error, rem, exp} ->
    #     any(rest, [{rem, exp} | errors]).(input)
    # end
  # end


  @spec until(parser, parser) :: parser
  def until(parser, stop), do: fn (input) -> _until(parser, stop, [], input) end
  defp _until(parser, stop, acc, input) do
    case stop.(input) do
      {:ok, _} ->
        {:ok, {acc, input}}
      _err ->
        case parser.(input) do
          {:ok, {value, rest}} ->
            _until(parser, stop, acc ++ value, rest)
          err ->
            err
        end
    end
    # TODO return deepest err
  end

  @spec sequence([parser]) :: parser
  def sequence(parsers) when length(parsers) > 0, do: fn (input) ->
    _sequence(parsers, [], input)
  end

  defp _sequence([parser], acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        {:ok, {acc ++ value, rest}}
      err ->
        err
    end
  end

  defp _sequence([parser | rem_parsers], acc, input) do
    case parser.(input) do
      {:ok, {value, rest}} ->
        _sequence(rem_parsers, acc ++ value, rest)
      err ->
        err
    end
  end

  @doc """
  Parse something between two parsers.

  The surrounding parser values are omitted from successful parse result.
  """
  @spec between(parser, parser, parser) :: parser
  def between(a, b, c), do: sequence([skip(a), b, skip(c)])

  @doc """
  Parse end of file.
  """
  @spec eof() :: parser
  def eof(), do: fn
    ([]) -> {:ok, {[], []}}
    input -> {:error, input, []}
  end

  @doc """
  Transform successful parse result using given function.
  """
  @spec transform(transformer, parser) :: parser
  def transform(f, parser), do: fn (input) ->
    case parser.(input) do
      {:ok, {value, rest}} ->
        {:ok, {f.(value), rest}}
      err ->
        err
    end
  end

  @doc """
  Wrap parser in a thunk to delay evaluation.

  Has the effect of preventing infinite loops in self-referential parsers.
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
      err -> throw err
    end
  end

  @doc """
  Wrap parser result into a list.
  """
  @spec wrap(parser) :: parser
  def wrap(parser), do: transform(fn (val) -> [val] end, parser)
end
