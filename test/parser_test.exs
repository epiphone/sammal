defmodule Sammal.ParserTest do
  use ExUnit.Case, async: true
  doctest Sammal.Parser

  import Sammal.Parser
  alias Sammal.Token


  test "parse/1 parses symbols" do
    assert ["12"] |> tokens |> parse == {[12], []}
    assert ["2", "3"] |> tokens |> parse == {[2, 3], []}
    assert ["2.1", "3"] |> tokens |> parse == {[2.1, 3], []}
    assert ["atom", "3"] |> tokens |> parse == {[:atom, 3], []}
    assert ~w/1 2 ( define x )/ |> tokens |> parse == {[1, 2, [:define, :x]], []}
  end

  test "parse/1 parses nested expressions" do
    assert ~w/( define x 10 )/ |> tokens |> parse == {[[:define, :x, 10]], []}
    assert ~w/( + ( - 3 1 ) ( \/ 6 2 ) )/ |> tokens |> parse == {[[:+, [:-, 3, 1], [:/, 6, 2]]], []}
    assert ~w/( 1 ( 2 ( 3 ( 4 ) 5 ) 6 ) 7 )/ |> tokens |> parse == {[[1, [2, [3, [4], 5], 6], 7]], []}
    assert ~w/a 10 ( x ) ( y )/ |> tokens |> parse == {[:a, 10, [:x], [:y]], []}
  end

  test "parse_one/1 converts tokens into matching data types" do
    assert parse_one(%Token{lexeme: "12"}) == 12
    assert parse_one(%Token{lexeme: "12.12"}) == 12.12
    assert parse_one(%Token{lexeme: "atom"}) == :atom
    assert parse_one(%Token{lexeme: "-10"}) == -10
  end

  defp tokens(arr), do: Enum.map(arr, &%Token{lexeme: &1})
end
