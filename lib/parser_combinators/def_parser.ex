defmodule Sammal.ParserCombinators.DefParser do
  @moduledoc """
  A macro wrapper for parser combinators.
  """
  alias Sammal.ParserCombinators.Cache


  @doc """
  Define a memoized continuation passing style parser combinator.

  Memoization adapted from: (Gustavo Brunoro) https://gist.github.com/brunoro/6159378
  """
  defmacro def_parser(head = {name, _, vars}, do: body) do
    quote do
      def unquote(head) do
        Cache.init_if_not_exists()
        fn (input, cont) ->
          key = {__MODULE__, unquote(name), unquote(vars), input} # TODO use input length or index instead

          case Cache.get(key) do
            nil ->
              Cache.put(key, {[cont], []})
              parser = unquote(body)
              parser.(input, fn (result) ->
                {conts, results} = Cache.get(key)
                if not Enum.member?(results, result) do
                  Cache.put(key, {conts, [result | results]})
                  for stored_cont <- conts, do: stored_cont.(result)
                end
              end)
            {conts, results} ->
              Cache.put(key, {[cont | conts], results})
              for res <- results, do: cont.(res)
          end
        end
      end
    end
  end
end
