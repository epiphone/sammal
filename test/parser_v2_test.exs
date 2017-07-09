# credo:disable-for-this-file Credo.Check.Readability.MaxLineLength
defmodule Sammal.ParserV2Test do
  use ExUnit.Case, async: true
  doctest Sammal.ParserV2

  import Sammal.ParserV2
  import Sammal.ParserCombinators, only: [many: 1]
  import Sammal.Utils, only: [map_deep: 2]
  alias Sammal.Expr


  test "parses numbers" do
    assert_parse [1], number, [1]
    assert_parse [1.2, 14], number, [1.2], [14]
    assert_error ["12"], number
    assert_parse [1, 2, :third], many(number), [1, 2], [:third]
  end

  test "parses strings" do
    assert_parse ["x"], string, ["x"]
    assert_parse ["var", "define"], string, ["var"], ["define"]
    assert_error [12], string, :unexpected
  end

  test "parses symbols" do
    assert_parse [:symbol], symbol, [:symbol]
    assert_parse [:var, :define], symbol, [:var], [:define]
    assert_error ["symbol"], symbol, :unexpected
  end

  test "parses specific tokens" do
    assert_parse [:"("], token(:"("), [:"("]
    assert_parse [:"#("], token(:"#("), [:"#("]
    assert_error ["("], token(:"(")
  end

  test "parses primitives" do
    assert_parse [1, "2nd", :third], primitive, [1], ["2nd", :third]
    assert_parse ["2nd", :third], primitive, ["2nd"], [:third]
    assert_parse [:third, 1], primitive, [:third], [1]
    assert_parse [1, "2nd", :third], many(primitive), [1, "2nd", :third], []
  end

  test "parses expressions" do
    assert_parse [10], expression, [10]
    assert_parse [10, :"(", :x, :")"], expression, [10], [:"(", :x, :")"]
    assert_parse [:"(", 10, :")"], expression, [[10]]
    assert_parse [:"(", :define, :x, 10, :")"], expression, [[:define, :x, 10]]
    assert_parse ~w/( x ( y ) )/a, expression, [[:x, [:y]]]
  end

  test "parses deeply nested expressions" do
    assert_parse ~w/( x ( y ) )/a, expression, [[:x, [:y]]]
    assert_parse ~w/( ( ( x ) ) ( y ) )/a, expression, [[[[:x]], [:y]]]
    assert_parse ~w/( + ( - a b ) ( \/ c d ) )/a, expression, [[:+, [:-, :a, :b], [:/, :c, :d]]]
    assert_parse ~w/( a ( b ( c ( d ) c ) b ) a )/a, expression, [[:a, [:b, [:c, [:d], :c], :b], :a]]
  end

  test "returns errors on invalid forms" do
    assert_error ~w/( x/a, sammal
    assert_error ~w/( x ( y )/a, sammal
    assert_error ~w/x/a, sammal
    assert_error ~w/( ) )/a, sammal
    assert_error ~w/( x y ) )/a, sammal
    assert_error ~w/( ( )/a, sammal
    assert_error ~w/( ( x )/a, sammal
    assert_error ~w/( ( x ( y ) )/a, sammal
    assert_error ~w/( ( ( x ) )/a, sammal
    assert_error ~w/( ' ( )/a, sammal
    assert_error ~w/( ' ( x )/a, sammal
  end

  test "parses empty lists" do
    assert_parse ~w/( )/a, expression, [[]]
    assert_parse ~w/( ( ( ) ) )/a, expression, [[[[]]]]
    assert_parse ~w/( def x ( ) )/a, expression, [[:def, :x, []]]
  end

  test "extends quoted expressions" do
    assert_parse ~w/' x/a, expression, [[:quote, :x]]
    assert_parse ~w/' ( x )/a, expression, [[:quote, [:x]]]
    assert_parse ~w/( ' x y )/a, expression, [[[:quote, :x], :y]]
    assert_parse ~w/' ( x y )/a, expression, [[:quote, [:x, :y]]]
    assert_parse ~w/( ' x ' y )/a, expression, [[[:quote, :x], [:quote, :y]]]
  end


  # Helpers to avoid boilerplate in tests:

  defp assert_parse(input, parser, value, rem \\ []) do
    assert {:ok, {tokens(value), tokens(rem)}} == input |> tokens |> parser.()
  end

  defp assert_error(input, parser, error \\ nil) do
    res = input |> tokens |> parser.()
    if error do
      assert {:error, ^error} = res
    else
      assert {:error, _} = res
    end
  end

  defp tokens(vals), do: map_deep(vals, &%Expr{val: &1})
end
