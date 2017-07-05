defmodule Sammal.ParserTest do
  use ExUnit.Case, async: true
  doctest Sammal.Parser

  import Sammal.Parser
  import Sammal.Tokenizer, only: [tokenize: 1]
  import Sammal.Utils, only: [map_deep: 2]
  alias Sammal.{SammalError}


  test "parses atoms" do
    assert_parse "1", [1]
    assert_parse "23", [23]
    assert_parse "2.1", [2.1]
    assert_parse "x", [:x]
    assert_parse "true", [:true]
    assert_parse "#f", [:false]
    assert_parse "somesymbol", [:"somesymbol"]
    assert_parse "a_messy-symbol", [:"a_messy-symbol"]
    assert_parse "()", [[]]
    assert_parse "  (     ) ", [[]]
  end

  test "parses a single expression" do
    assert_parse "()", [[]]
    assert_parse "(x)", [[:x]]
    assert_parse "(define x 10)", [[:define, :x, 10]]
  end

  test "parses nested expressions" do
    assert_parse "(x (y))", [[:x, [:y]]]
    assert_parse "(((x)) (y))", [[[[:x]], [:y]]]
    assert_parse "(+ (- 3 1) (\/ 6 2))", [[:+, [:-, 3, 1], [:/, 6, 2]]]
    assert_parse "(1 (2 (3 (4) 3) 2) 1)", [[1, [2, [3, [4], 3], 2], 1]]
  end

  test "extends quoted expressions" do
    assert_parse "'x", [[:quote, :x]]
    assert_parse "('x y)", [[[:quote, :x], :y]]
    assert_parse "'(x 10)", [[:quote, [:x, 10]]]
    assert_parse "('x 'y)", [[[:quote, :x], [:quote, :y]]]
  end

  test "returns error when parsing invalid expressions" do
    assert {:error, %SammalError{type: :unexpected}} = expr("x")
    assert {:error, %SammalError{type: :unexpected}} = expr(")")
    assert {:error, %SammalError{type: :unexpected}} = expr("x y)")
    assert {:error, %SammalError{type: :unmatched_paren}} = expr("(")
    assert {:error, %SammalError{type: :unmatched_paren}} = expr("(x")
    assert {:error, %SammalError{type: :unmatched_paren}} = expr("(x (y)")
    assert {:error, %SammalError{type: :unmatched_paren}} = expr("((x)")
    assert {:error, %SammalError{type: :unmatched_paren}} = any("'(")
    assert {:error, %SammalError{type: :unmatched_paren}} = any("'(x")
  end


  # Helpers:

  defp assert_parse(raw, expr) do
    assert {:ok, {ast, []}} = {[], raw |> tokenize |> elem(1)} |> parse_next
    assert map_deep(ast, &(&1.val)) == expr
  end
  defp any(line), do: {[], line |> tokenize |> elem(1)} |> parse_next
  defp expr(line), do: {[], line |> tokenize |> elem(1)} |> parse_expression
end
