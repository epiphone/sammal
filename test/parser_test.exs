defmodule Sammal.ParserTest do
  use ExUnit.Case, async: true
  doctest Sammal.Parser

  import Sammal.Parser

  test "parses symbols leaving the remainder" do
    assert parse(["12"]) == {12, []}
    assert parse(["2", "3"]) == {2, ["3"]}
    assert parse(["2.1", "3"]) == {2.1, ["3"]}
    assert parse(["atom", "3"]) == {:atom, ["3"]}
    assert parse(~w/1 2 ( define x )/) == {1, ~w/2 ( define x )/}
  end

  test "parses expressions" do
    assert parse(~w/( define x 10 )/) == {[:define, :x, 10], []}
    assert parse(~w/( + ( - 3 1 ) ( \/ 6 2 ) )/) == {[:+, [:-, 3, 1], [:/, 6, 2]], []}
  end
end
