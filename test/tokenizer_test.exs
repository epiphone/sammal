defmodule Sammal.TokenizerTest do
  use ExUnit.Case, async: true
  doctest Sammal.Tokenizer

  import Sammal.Tokenizer


  test "tokenizes a raw input string" do
    assert tokenize("(define x 10)") == ~w/( define x 10 )/
    assert tokenize(" ( begin (define x (1 2)))") == ~w/( begin ( define x ( 1 2  ) ) )/
  end

  test "omits empty strings" do
    assert tokenize(" ") == []
    assert tokenize(" x   y  z  ") == ~w/x y z/
  end

  test "tokenizes parenthesis separately" do
    assert tokenize("(a)") == ~w/( a )/
    assert tokenize("((()))") == ~w/( ( ( ) ) )/
  end

  test "tokenizes strings with whitespace" do
    assert tokenize("\"asd\"") == ["\"asd\""]
    assert tokenize("\"asd dsa\"") == ["\"asd dsa\""]
    assert tokenize("(define x \"asd dsa\")") == ["(", "define", "x", "\"asd dsa\"", ")"]
  end

  test "ignores comment lines" do
    assert tokenize(";") == []
    assert tokenize(";some comment") == []
    assert tokenize("; some comment") == []
  end
end
