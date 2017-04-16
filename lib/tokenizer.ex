defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """
  alias Sammal.Token

  @doc ~S"""
  Splits a line of raw input into a list of token strings.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(define x 10)")
    ["(", "define", "x", "10", ")"]
    [%Sammal.Token{lexeme: "(", line: 0, index: 0},
     %Sammal.Token{lexeme: "define", line: 0, index: 1},
     %Sammal.Token{lexeme: "x", line: 0, index: 8},
     %Sammal.Token{lexeme: "10", line: 0, index: 10},
     %Sammal.Token{lexeme: ")", line: 0, index: 12}]
  """
  def tokenize(line, row_index \\ 0)
  def tokenize(";" <> _, row_index), do: []
  def tokenize(line, row_index) do
    Regex.scan(~r/([()]|"[^"]*"?|[\w-]+)/, line, return: :index)
    |> Enum.map(fn [_ | [{i, n}]] ->
      %Token{lexeme: String.slice(line,  i, n),
             line: row_index,
             index: i}
    end)
  end
end
