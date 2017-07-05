defmodule Sammal.Tokenizer do
  @moduledoc """
  Tokenizer and various helper methods.
  """
  alias Sammal.{Expr, SammalError}


  @tokenizer_regex ~r/(['()]|"[^"]*"?|[\w-+\/.#]+)/

  @doc ~S"""
  Split a line of raw input into a list of Node structs.

  ## Example

    iex> Sammal.Tokenizer.tokenize("(define x 10)")
    {:ok, [%Sammal.Expr{lex: "(", line: 0, row: 0, val: :"(", ctx: "(define x 10)"},
           %Sammal.Expr{lex: "define", line: 0, row: 1, val: :define, ctx: "(define x 10)"},
           %Sammal.Expr{lex: "x", line: 0, row: 8, val: :x, ctx: "(define x 10)"},
           %Sammal.Expr{lex: "10", line: 0, row: 10, val: 10, ctx: "(define x 10)"},
           %Sammal.Expr{lex: ")", line: 0, row: 12, val: :")", ctx: "(define x 10)"}]}
  """
  def tokenize(line, line_index \\ 0)
  def tokenize(";" <> _, _), do: {:ok, []}
  def tokenize(line, line_index) do
    tokens =
      @tokenizer_regex
      |> Regex.scan(line, capture: :first, return: :index)
      |> Enum.map(fn [{row, n}] ->
        lex = String.slice(line, row, n)
        token = %Expr{ctx: line, row: row, lex: lex, line: line_index}

        case lexeme_to_value(lex) do
          {:ok, val} -> %{token | val: val}
          {:error, error} -> throw SammalError.new(error, token)
        end
      end)

    {:ok, tokens}
  catch
    %SammalError{} = error -> {:error, error}
  end

  @doc ~S"""
  Given a lexeme, return a matching Elixir value (or an error).

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

  def lexeme_to_value(lex) do
    case Integer.parse(lex) do
      {val, ""} -> {:ok, val}
      :error -> {:ok, String.to_atom(lex)}
      {val, _} -> case Float.parse(lex) do
        {val, ""} -> {:ok, val}
        _ -> {:ok, String.to_atom(lex)}
      end
    end
  end
end
