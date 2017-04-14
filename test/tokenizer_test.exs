defmodule Sammal.TokenizerTest do
  use ExUnit.Case, async: true
  doctest Sammal.Tokenizer

  import Sammal.Tokenizer
  alias Sammal.Token


  test "tokenizes into a Token struct" do
    assert tokenize("x value 10") == [%Token{lexeme: "x", line: 0, index: 0},
                                      %Token{lexeme: "value", line: 0, index: 2},
                                      %Token{lexeme: "10", line: 0, index: 8}]
  end

  test "tokenizes a raw input string" do
    assert tokenize("(define x 10)") |> Enum.map(&(&1.lexeme)) == ~w/( define x 10 )/
    assert tokenize(" ( begin (define x (1 2)))") |> Enum.map(&(&1.lexeme)) == ~w/( begin ( define x ( 1 2  ) ) )/
  end

  test "omits empty strings" do
    assert tokenize(" ") == []
    assert tokenize(" x   y  z  ") |> Enum.map(&(&1.lexeme)) == ~w/x y z/
  end

  test "tokenizes parenthesis separately" do
    assert tokenize("(a)") |> Enum.map(&(&1.lexeme)) == ~w/( a )/
    assert tokenize("((()))") |> Enum.map(&(&1.lexeme)) == ~w/( ( ( ) ) )/
  end

  test "tokenizes strings with whitespace" do
    assert tokenize("\"asd\"") |> Enum.map(&(&1.lexeme)) == ["\"asd\""]
    assert tokenize("\"asd dsa\"") |> Enum.map(&(&1.lexeme)) == ["\"asd dsa\""]
    assert tokenize("(define x \"asd dsa\")") |> Enum.map(&(&1.lexeme)) == ["(", "define", "x", "\"asd dsa\"", ")"]
  end

  test "ignores comment lines" do
    assert tokenize(";") == []
    assert tokenize(";some comment") == []
    assert tokenize("; some comment") == []
  end
end
