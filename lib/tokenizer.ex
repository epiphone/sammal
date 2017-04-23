defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """
  alias Sammal.{SammalError, Token}


  @tokenizer_regex ~r/(['()]|"[^"]*"?|[\w-+\/.#]+)/

  @doc ~S"""
  Splits a line of raw input into a list of token strings.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(define x 10)")
    ["(", "define", "x", "10", ")"]
    {[%Sammal.Token{lexeme: "(", line: 0, index: 0, value: :"("},
      %Sammal.Token{lexeme: "define", line: 0, index: 1, value: :define},
      %Sammal.Token{lexeme: "x", line: 0, index: 8, value: :x},
      %Sammal.Token{lexeme: "10", line: 0, index: 10, value: 10},
      %Sammal.Token{lexeme: ")", line: 0, index: 12, value: :")"}], []}
  """
  def tokenize(line, row_index \\ 0)
  def tokenize(";" <> _, row_index), do: {[], []}
  def tokenize(line, row_index) do
    @tokenizer_regex
    |> Regex.scan(line, return: :index)
    |> Enum.map(fn [_ | [{i, n}]] ->
      %Token{lexeme: String.slice(line, i, n), line: row_index, index: i}
    end)
    |> Enum.reduce({[], []}, fn (token, {tokens, errors}) ->
      case lexeme_to_value(token.lexeme) do
        {:ok, value} ->
          {tokens ++ [%{token | value: value}], errors}
        {:error, type} ->
          {tokens, errors ++ [%SammalError{token: token, type: type}]}
      end
    end)
  end

  @doc ~S"""
  Given a lexeme, returns a matching Elixir value (or an error).

  ## Example

    iex> Sammal.Tokenizer.lexeme_to_value("12")
    {:ok, 12}

    iex> Sammal.Tokenizer.lexeme_to_value("12.12")
    {:ok, 12.12}

    iex> Sammal.Tokenizer.lexeme_to_value("\"12\"")
    {:ok, "12"}
  """
  def lexeme_to_value("#t"), do: {:ok, true}
  def lexeme_to_value("#f"), do: {:ok, false}
  def lexeme_to_value("\"" <> tail) do
    if String.ends_with?(tail, "\"") do
      {:ok, String.slice(tail, 0..-2)}
    else
      {:error, :ending_quote}
    end
  end

  def lexeme_to_value(lexeme) do
    case Integer.parse(lexeme) do
      {val, ""} -> {:ok, val}
      :error -> {:ok, String.to_atom(lexeme)}
      {val, _} -> case Float.parse(lexeme) do
        {val, ""} -> {:ok, val}
        _ -> {:ok, String.to_atom(lexeme)}
      end
    end
  end
end
