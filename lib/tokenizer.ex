defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """
  alias Sammal.{SammalError, Token}


  @tokenizer_regex ~r/(['()]|"[^"]*"?|[\w-+\/.#]+)/

  @doc ~S"""
  Split a line of raw input into a list of Token structs.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(define x 10)")
    {:ok, [%Sammal.Token{lexeme: "(", line: 0, index: 0, value: :"("},
           %Sammal.Token{lexeme: "define", line: 0, index: 1, value: :define},
           %Sammal.Token{lexeme: "x", line: 0, index: 8, value: :x},
           %Sammal.Token{lexeme: "10", line: 0, index: 10, value: 10},
           %Sammal.Token{lexeme: ")", line: 0, index: 12, value: :")"}]}
  """
  def tokenize(line, row_index \\ 0)
  def tokenize(";" <> _, row_index), do: {:ok, []}
  def tokenize(line, row_index) do
    try do
      tokens =
        @tokenizer_regex
        |> Regex.scan(line, capture: :first, return: :index)
        |> Enum.map(fn [{index, n}] ->
          lexeme = String.slice(line, index, n)
          token = %Token{index: index, lexeme: lexeme, line: row_index}

          case token_to_value(token) do
            {:ok, value} -> %{token | value: value}
            {:error, error} -> throw error
          end
        end)

      {:ok, tokens}
    catch
      %SammalError{} = error -> {:error, error}
    end
  end

  @doc ~S"""
  Given a token, returns a matching Elixir value (or an error).

  ## Example

    iex> Sammal.Tokenizer.token_to_value(%Sammal.Token{lexeme: "12"})
    {:ok, 12}

    iex> Sammal.Tokenizer.token_to_value(%Sammal.Token{lexeme: "12.12"})
    {:ok, 12.12}

    iex> Sammal.Tokenizer.token_to_value(%Sammal.Token{lexeme: "\"12\""})
    {:ok, "12"}
  """
  def token_to_value(%Token{lexeme: "#t"}), do: {:ok, true}
  def token_to_value(%Token{lexeme: "#f"}), do: {:ok, false}
  def token_to_value(%Token{lexeme: "\"" <> tail} = token) do
    if String.ends_with?(tail, "\"") do
      {:ok, String.slice(tail, 0..-2)}
    else
      {:error, SammalError.new(:ending_quote, token)}
    end
  end

  def token_to_value(%Token{lexeme: lexeme}) do
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
