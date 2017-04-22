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
    [%Sammal.Token{lexeme: "(", line: 0, index: 0, value: :"("},
     %Sammal.Token{lexeme: "define", line: 0, index: 1, value: :define},
     %Sammal.Token{lexeme: "x", line: 0, index: 8, value: :x},
     %Sammal.Token{lexeme: "10", line: 0, index: 10, value: 10},
     %Sammal.Token{lexeme: ")", line: 0, index: 12, value: :")"}]
  """
  def tokenize(line, row_index \\ 0)
  def tokenize(";" <> _, row_index), do: []
  def tokenize(line, row_index) do
    Regex.scan(~r/(['()]|"[^"]*"?|[\w-+\/.]+)/, line, return: :index)
    |> Enum.map(fn [_ | [{i, n}]] ->
      lexeme = String.slice(line,  i, n)
      %Token{lexeme: lexeme,
             line: row_index,
             index: i,
             value: lexeme_to_value(lexeme)}
    end)
  end

  @doc ~S"""
  Given a lexeme, returns a matching Elixir value.

  ## Example

    iex> Sammal.Tokenizer.lexeme_to_value("12")
    12

    iex> Sammal.Tokenizer.lexeme_to_value("12.12")
    12.12

    iex> Sammal.Tokenizer.lexeme_to_value("\"12\"")
    "12"
  """
  def lexeme_to_value("\"" <> tail) do
    if String.ends_with?(tail, "\"") do
      String.slice(tail, 0..-2)
    else
      raise "Invalid string: \"#{tail}" # TODO handle properly
    end
  end

  def lexeme_to_value(lexeme) do
    case Integer.parse(lexeme) do
      {val, ""} -> val
      :error -> String.to_atom(lexeme)
      {val, _} -> case Float.parse(lexeme) do
        {val, ""} -> val
        _ -> String.to_atom(lexeme)
      end
    end
  end
end
