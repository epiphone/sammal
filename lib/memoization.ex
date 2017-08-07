defmodule Sammal.Memoization do
  @moduledoc """
  Utilities for function memoization.

  We're using [ETS](https://elixirschool.com/en/lessons/specifics/ets/)
  to store our memo table since Elixir doesn't support mutable variables.
  """
  @ets_table_name :_sammal_memo_table


  # @doc """
  # Define a memoized function.

  # Adapted from : (Gustavo Brunoro) https://gist.github.com/brunoro/6159378
  # """
  # defmacro defmemo(head = {name, _, vars}, do: body) do
  #   quote do
  #     @memo_table_prefix :_sammal_memo

  #     def unquote(head) do
  #       memo_table = FastGlobal.get(@memo_table_key, %{})
  #       key = {__MODULE__, unquote(name), unquote(vars)}

  #       case Map.get(memo_table, key) do
  #         nil ->
  #           IO.inspect {"cache miss", key}, pretty: true
  #           result = unquote(body)
  #           FastGlobal.put(@memo_table_key, Map.put(memo_table, key, result))
  #           result
  #         value ->
  #           IO.inspect {"cache hit!", key}, pretty: true
  #           value
  #       end
  #     end
  #   end
  # end

  # defmacro defparser(head = {name, _, vars}, do: body) do
  #   quote do
  #     @memo_table_key :_sammal_memo_table

  #     def unquote(head) do
  #       parser = unquote(body)
  #       fn (input) ->
  #         memo_table = FastGlobal.get(@memo_table_key, %{})
  #         key = {__MODULE__, unquote(name), unquote(vars), input} # TODO use input length or index instead

  #         case Map.get(memo_table, key) do
  #           nil ->
  #             IO.inspect {"cache miss", key}, pretty: true
  #             result = parser.(input)
  #             FastGlobal.put(@memo_table_key, Map.put(memo_table, key, result))
  #             result
  #           value ->
  #             IO.inspect {"cache hit!", key}, pretty: true
  #             value
  #         end
  #       end
  #     end
  #   end
  # end

  def init_ets_if_not_exists() do
    if :ets.info(@ets_table_key) == :undefined do
      :ets.new(@ets_table_key, [:set, :named_table, :protected])
    end
  end

  defmacro defcpsparser(head = {name, _, vars}, do: body) do
    quote do
      def unquote(head) do
        init_ets_if_not_exists()
        parser = unquote(body)
        fn (input, cont) ->
          key = {__MODULE__, unquote(name), unquote(vars), input} # TODO use input length or index instead

          case :ets.lookup(@ets_table_key, key) do
            [] ->
              IO.inspect {"cache miss", {unquote(name), input}}, pretty: true
              :ets.insert(@ets_table_key, {key, {[cont], []}}) # push cont
              parser.(input, fn (result) ->
                [{_, {conts, results}}] = :ets.lookup(@ets_table_key, key)
                if not Enum.member?(results, result) do
                  :ets.insert(@ets_table_key, {key, {conts, [result | results]}}) # push result
                  for stored_cont <- conts, do: stored_cont.(result)
                end
              end)
            [{_, {conts, results}}] ->
              IO.inspect {"cache hit!", {unquote(name), input}, {conts, results}}, pretty: true
              :ets.insert(@ets_table_key, {key, {[cont | conts], results}})
              for res <- results, do: cont.(res)
          end
        end
      end
    end
  end
end
