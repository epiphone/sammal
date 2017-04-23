defmodule Sammal.ParserTest do
  use ExUnit.Case, async: true
  doctest Sammal.Parser

  import Sammal.{Parser, Tokenizer}
  alias Sammal.{SammalError, Token}


  test "parses symbols" do
    assert ast("12") == [12]
    assert ast("2 3") == [2, 3]
    assert ast("2.1 3") == [2.1, 3]
    assert ast("atom 3") == [:atom, 3]
    assert ast("1 2 ( define x )") == [1, 2, [:define, :x]]
  end

  test "parses nested expressions" do
    assert ast("(define x 10 )") == [[:define, :x, 10]]
    assert ast("(+ (- 3 1) (\/ 6 2 ) )") == [[:+, [:-, 3, 1], [:/, 6, 2]]]
    assert ast("(1 ( 2 (3 (4 ) 5) 6 ) 7 )") == [[1, [2, [3, [4], 5], 6], 7]]
    assert ast("a 10 ( x ) (y )") == [:a, 10, [:x], [:y]]
  end

  test "extends quoted expressions" do
    assert ast("'x") == [[:quote, :x]]
    assert ast("'x y") == [[:quote, :x], :y]
    assert ast("'(x 10)") == [[:quote, [:x, 10]]]
    assert ast("'x 'y") == [[:quote, :x,], [:quote, :y]]
    # assert ast("'") == ?? # TODO
  end

  test "parses a single expression" do
    assert {[], [], []} = expression("()")
    assert {[:x, [:y], :z], [], []}= expression("(x (y) z)")
    assert {[:x, [:y]], [_, _], []} = expression("(x (y)) z)")
  end

  test "returns error when parsing invalid expressions" do
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("x")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression(")")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("(")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("x y)")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("(x")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("(x (y)")
    assert {_, _, [%SammalError{type: :unexpected_token}]} = expression("((x)")
  end

  defp ast(line), do: line |> tokenize |> elem(0) |> parse |> elem(0)
  defp expression(line), do: line |> tokenize |> elem(0) |> parse_expression
end
