defmodule Sammal.TokenizerTest do
  use ExUnit.Case, async: true
  doctest Sammal.Tokenizer

  import Sammal.Tokenizer


  test "tokenizes a raw input string" do
    assert tokenize("(define x 10)") == ~w/( define x 10 )/
    assert tokenize(" ( begin (define x (1 2)))") == ~w/( begin ( define x ( 1 2  ) ) )/
  end

  test "omits empty strings" do
    assert tokenize(" x   y  z  ") == ~w/x y z/
  end

  test "tokenizes parenthesis separately" do
    assert tokenize("(a)") === ~w/( a )/
    assert tokenize("((()))") === ~w/( ( ( ) ) )/
  end
end
