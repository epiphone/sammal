defmodule Sammal.TokenizerTest do
  use ExUnit.Case, async: true
  doctest Sammal.Tokenizer

  import Sammal.Tokenizer
  alias Sammal.{Expr, SammalError}


  test "tokenizes into Expr structs" do
    expected = [%Expr{lex: "x", line: 0, row: 0, val: :x, ctx: "x \"y\" 10"},
                %Expr{lex: "\"y\"", line: 0, row: 2, val: "y", ctx: "x \"y\" 10"},
                %Expr{lex: "10", line: 0, row: 6, val: 10, ctx: "x \"y\" 10"}]
    assert tokenize("x \"y\" 10") == {:ok, expected}
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

  test "tokenizes strings" do
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
    assert lexeme_to_value("+1") == {:ok, 1}
    assert lexeme_to_value("-10") == {:ok, -10}
    assert lexeme_to_value("some_symbol") == {:ok, :some_symbol}
    assert lexeme_to_value("\"not a symbol\"") == {:ok, "not a symbol"}
    assert lexeme_to_value("#t") == {:ok, true}
    assert lexeme_to_value("#f") == {:ok, false}
  end

  test "returns error when quotes unmatched" do
    assert {:error, :ending_quote} = lexeme_to_value("\"xs")
    assert {:error, :ending_quote} = lexeme_to_value("\"xs ys")
    assert {:error, :ending_quote} = lexeme_to_value("\"xs\" ys")
    assert {:error, :ending_quote} = lexeme_to_value("\"xs\"x\" ys zs")
  end

  test "allows unusual symbols" do
    assert lexeme_to_value("++1") == {:ok, :"++1"}
    assert lexeme_to_value("...") == {:ok, :"..."}
    assert lexeme_to_value("x1") == {:ok, :x1}
    assert lexeme_to_value("10f") == {:ok, :"10f"}
  end

  test "tokenizes quotes" do
    assert lexemes("'x") == ["'", "x"]
    assert lexemes("('x '(10)") == ["(", "'", "x", "'", "(", "10", ")"]
  end

  defp lexemes(line), do: line |> tokenize |> elem(1) |> Enum.map(&(&1.lex))
end
