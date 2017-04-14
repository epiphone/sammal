defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """

  @doc ~S"""
  Splits a line of raw input into a list of token strings.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(begin (define x 10))")
    ["(", "begin", "(", "define", "x", "10", ")", ")"]
  """
  def tokenize(";" <> _), do: []
  def tokenize(line, row_index \\ 0) do
    Regex.scan(~r/([()]|".*"|[\w-]+)/, line, return: :index)
    |> Enum.map(fn [_ | [{i, n}]] ->
      String.slice(line,  i, n)
    end)
  end
end
