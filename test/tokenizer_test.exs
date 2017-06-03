defmodule Sammal.TokenizerTest do
  use ExUnit.Case, async: true
  doctest Sammal.Tokenizer

  import Sammal.Tokenizer
  alias Sammal.{SammalError, Token}


  test "tokenizes into a Token struct" do
    assert tokenize("x \"y\" 10") == {:ok, [%Token{lexeme: "x", line: 0, index: 0, value: :x},
                                            %Token{lexeme: "\"y\"", line: 0, index: 2, value: "y"},
                                            %Token{lexeme: "10", line: 0, index: 6, value: 10}]}
  end

  test "ignore token and return error when invalid token" do
    assert {:error, %SammalError{}} = tokenize "\"invalid_string"
  end

  test "tokenizes a raw input string" do
    assert lexemes("(define x 10)") == ~w/( define x 10 )/
    assert lexemes(" ( begin (define x (1 2)))") == ~w/( begin ( define x ( 1 2  ) ) )/
  end

  test "omits empty strings" do
    assert lexemes(" ") == []
    assert lexemes(" x   y  z  ") == ~w/x y z/
  end

  test "tokenizes parenthesis separately" do
    assert lexemes("(a)") == ~w/( a )/
    assert lexemes("((()))") == ~w/( ( ( ) ) )/
  end

  test "tokenizes strings with whitespace" do
    assert lexemes("\"asd\"") == ["\"asd\""]
    assert lexemes("\"asd dsa\"") == ["\"asd dsa\""]
    assert lexemes("(define x \"asd dsa\")") == ["(", "define", "x", "\"asd dsa\"", ")"]
  end

  test "tokenizes floats" do
    assert lexemes("12.12") == ["12.12"]
    assert lexemes("-12.12 0.04") == ["-12.12", "0.04"]
  end

  test "ignores comment lines" do
    assert lexemes(";") == []
    assert lexemes(";some comment") == []
    assert lexemes("; some comment") == []
  end

  test "converts lexemes into matching data Elixir values" do
    assert lexeme_to_value("12") == {:ok, 12}
    assert lexeme_to_value("12.12") == {:ok, 12.12}
    assert lexeme_to_value("-10") == {:ok, -10}
    assert lexeme_to_value("atom") == {:ok, :atom}
    assert lexeme_to_value("\"not an atom\"") == {:ok, "not an atom"}
    assert lexeme_to_value("#t") == {:ok, true}
    assert lexeme_to_value("#f") == {:ok, false}
  end

  test "returns an error when odd number of quotes" do
    assert {:error, %{type: :ending_quote}} = lexeme_to_value("\"xs")
    assert {:error, %{type: :ending_quote}} = lexeme_to_value("\"xs ys")
    assert {:error, %{type: :ending_quote}} = lexeme_to_value("\"xs\" ys")
    assert {:error, %{type: :ending_quote}} = lexeme_to_value("\"xs\"x\" ys zs")
  end

  test "tokenizes quotes" do
    assert lexemes("'x") == ["'", "x"]
    assert lexemes("('x '(10)") == ["(", "'", "x", "'", "(", "10", ")"]
  end

  defp lexeme_to_value(lexeme), do: token_to_value(%Token{lexeme: lexeme})

  defp lexemes(line), do: line |> tokenize |> elem(1) |> Enum.map(&(&1.lexeme))
end
