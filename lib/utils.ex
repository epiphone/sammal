defmodule Sammal.Utils do
  @moduledoc """
  Various utility functions.
  """

  @doc """
  Map a function over each item of a deeply nested list.

  ## Example

      iex> Sammal.Utils.map_deep([1, 2, [3, [4], 5], 6], fn x -> x * 2 end)
      [2, 4, [6, [8], 10], 12]
  """
  @spec map_deep(Enumerable.t, (any -> any)) :: list
  def map_deep([head | rest], func) when is_list(head) do
    [map_deep(head, func) | map_deep(rest, func)]
  end
  def map_deep([head | rest], func), do: [func.(head) | map_deep(rest, func)]
  def map_deep([], _), do: []
end
