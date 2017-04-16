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
    assert lexemes("(define x 10)") == ~w/( define x 10 )/
    assert lexemes(" ( begin (define x (1 2)))") == ~w/( begin ( define x ( 1 2  ) ) )/
  end

  test "omits empty strings" do
    assert tokenize(" ") == []
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

  test "tokenizes odd number of quotes" do
    assert lexemes("\"xs") == ["\"xs"]
    assert lexemes("\"xs ys") == ["\"xs ys"]
    assert lexemes("\"xs\" ys") == ["\"xs\"", "ys"]
    assert lexemes("\"xs\"x\" ys zs") == ["\"xs\"", "x", "\" ys zs"]
    assert lexemes("\"xs\"(x)\"") == ["\"xs\"", "(", "x", ")", "\""]
  end

  test "ignores comment lines" do
    assert tokenize(";") == []
    assert tokenize(";some comment") == []
    assert tokenize("; some comment") == []
  end

  defp lexemes(line), do: line |> tokenize |> Enum.map(&(&1.lexeme))
end
