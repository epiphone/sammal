defmodule Sammal.ParserTest do
  use ExUnit.Case, async: true
  doctest Sammal.Parser

  import Sammal.{Parser, Tokenizer}
  alias Sammal.Token


  test "parses symbols" do
    assert "12" |> tokenize |> parse == {[12], []}
    assert "2 3" |> tokenize |> parse == {[2, 3], []}
    assert "2.1 3" |> tokenize |> parse == {[2.1, 3], []}
    assert "atom 3" |> tokenize |> parse == {[:atom, 3], []}
    assert "1 2 ( define x )" |> tokenize |> parse == {[1, 2, [:define, :x]], []}
  end

  test "parses nested expressions" do
    assert "(define x 10 )" |> tokenize |> parse == {[[:define, :x, 10]], []}
    assert "(+ (- 3 1) (\/ 6 2 ) )" |> tokenize |> parse == {[[:+, [:-, 3, 1], [:/, 6, 2]]], []}
    assert "(1 ( 2 (3 (4 ) 5) 6 ) 7 )" |> tokenize |> parse == {[[1, [2, [3, [4], 5], 6], 7]], []}
    assert "a 10 ( x ) (y )" |> tokenize |> parse == {[:a, 10, [:x], [:y]], []}
  end

  test "extends quoted expressions" do
    assert "'x" |> tokenize |> parse == {[[:quote, :x]], []}
    assert "'x y" |> tokenize |> parse == {[[:quote, :x], :y], []}
    assert "'(x 10)" |> tokenize |> parse == {[[:quote, [:x, 10]]], []}
    assert "'x 'y" |> tokenize |> parse == {[[:quote, :x,], [:quote, :y]], []}
    # assert "'" |> tokenize |> parse == ?? # TODO
  end
end
