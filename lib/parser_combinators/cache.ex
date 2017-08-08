defmodule Sammal.ParserCombinators.Cache do
  @moduledoc """
  A cache for function memoization.

  We're using Erlang's built-in in-memory storage
  [ETS](http://learnyousomeerlang.com/ets) to store our memoization table.
  """
  @ets_table_name :sammal_memo_table


  @doc """
  Initialize memoization table if it's not already initialized.
  """
  def init_if_not_exists() do
    if :ets.info(@ets_table_name) == :undefined do
      :ets.new(@ets_table_name, [:set, :named_table, :protected, read_concurrency: true])
    end
  end

  @doc """
  Get a memoized value by key.
  """
  def get(key) do
    case :ets.lookup(@ets_table_name, key) do
      [] -> nil
      [{_, val}] -> val
    end
  end

  @doc """
  Insert a new memoized value.
  """
  def put(key, val), do: :ets.insert(@ets_table_name, {key, val})
end
