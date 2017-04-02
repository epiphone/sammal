defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """

  @doc ~S"""
  Splits a raw input string into a list of token strings.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(begin (define x 10))")
    ["(", "begin", "(", "define", "x", "10", ")", ")"]
  """
  def tokenize(input) do
    input
    |> String.replace(~r/[()]/, " \\0 ")
    |> String.split
  end
end
