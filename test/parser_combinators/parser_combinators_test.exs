# credo:disable-for-this-file Credo.Check.Readability.MaxLineLength
defmodule Sammal.ParserCombinatorsTest do
  use ExUnit.Case, async: true
  doctest Sammal.ParserCombinators

  import Sammal.ParserCombinators
  alias Sammal.ParserCombinators


  test "parses strings" do
    assert {:ok, {~w/x/, []}} = ~w/x/ |> string("x").()
    assert {:error, ~w/y/, "x"} = ~w/y/ |> string("x").()
    assert {:error, ~w/y x/, "x"} = ~w/y x/ |> string("x").()
    assert {:ok, {~w/x/, ["y"]}} = ~w/x y/ |> string("x").()
    assert {:ok, {~w/variable/, []}} = ~w/variable/ |> string("variable").()

    paren_open = string("(")
    assert {:ok, {~w/(/, []}} = ["("] |> paren_open.()
  end

  test "parsers numbers" do
    assert {:ok, {[1], []}} = [1] |> number().()
    assert {:ok, {[1.5], [2]}} = [1.5, 2] |> number().()
    assert {:error, ["1"], "a number"} = ["1"] |> number().()
  end

  test "parses both" do
    assert {:ok, {~w/x y/, []}} = ~w/x y/ |> both(string("x"), string("y")).()
    assert {:ok, {~w/x y/, ["z"]}} = ~w/x y z/ |> both(string("x"), string("y")).()
    assert {:ok, {~w/xs ys/, []}} = ~w/xs ys/ |> both(string("xs"), string("ys")).()
    assert {:error, ~w/y x/, "x"} = ~w/y x/ |> both(string("x"), string("y")).()
    assert {:error, ~w/z/, "y"} = ~w/x z/ |> both(string("x"), string("y")).()
  end

  test "parses either" do
    parser = either(string("x"), string("y"))
    assert {:ok, {~w/x/, []}} = ["x"] |> parser.()
    assert {:ok, {~w/y/, []}} = ["y"] |> parser.()
    assert {:error, _} = ["z"] |> parser.()

    binary = either(string("0"), string("1"))
    parser = both(binary, binary)
    assert {:ok, {~w/0 0/, []}} = ~w/0 0/ |> parser.()
    assert {:ok, {~w/0 1/, []}} = ~w/0 1/ |> parser.()
    assert {:ok, {~w/1 0/, []}} = ~w/1 0/ |> parser.()
    assert {:ok, {~w/1 1/, []}} = ~w/1 1/ |> parser.()
    assert {:error, _} = ~w/1/ |> parser.()
    assert {:error, _} = ~w/1 2/ |> parser.()
  end

  test "parses many" do
    assert {:ok, {[], []}} = ~w// |> many(string("a")).()
    assert {:ok, {[], ~w/b a/}} = ~w/b a/ |> many(string("a")).()
    assert {:ok, {~w/a/, []}} = ~w/a/ |> many(string("a")).()
    assert {:ok, {~w/a a a a/, []}} = ~w/a a a a/ |> many(string("a")).()
    assert {:ok, {~w/a/, ~w/b a/}} = ~w/a b a/ |> many(string("a")).()

    binary = either(string("0"), string("1"))
    assert {:ok, {~w/0 1 0 1/, []}} = ~w/0 1 0 1/ |> many(binary).()
    assert {:ok, {~w/1 1 0/, ~w/2 3/}} = ~w/1 1 0 2 3/ |> many(binary).()
  end

  test "parser many1" do
    assert {:error, [], "a"} = ~w// |> many1(string("a")).()
    assert {:ok, {~w/a/, []}} = ~w/a/ |> many1(string("a")).()
    assert {:ok, {~w/a a/, ~w/b/}} = ~w/a a b/ |> many1(string("a")).()
  end

  test "parses skip" do
    assert {:ok, {[], ~w/y z/}} = ~w/x y z/ |> skip(string("x")).()
    assert {:ok, {[], ~w/x x/}} = ~w/x x x/ |> skip(string("x")).()
    assert {:ok, {[], []}} = ~w/x x x/ |> skip(many(string("x"))).()
    assert {:ok, {[], ~w/y x/}} = ~w/y x/ |> skip(many(string("x"))).()
    assert {:error, ~w/y x/, "x"} = ~w/y x/ |> skip(string("x")).()
  end

  test "parses any" do
    assert {:ok, {~w/x/, ~w/rest/}} = ~w/x rest/ |> any([string("x")]).()
    assert {:error, _} = ~w/y rest/ |> any([string("x")]).()
    assert {:ok, {~w/y/, ~w/rest/}} = ~w/y rest/ |> any([string("x"), string("y")]).()
    assert {:error, _} = ~w/z rest/ |> any([string("x"), string("y")]).()
    assert {:ok, {~w/z/, ~w/rest/}} = ~w/z rest/ |> any([string("x"), string("y"), string("z")]).()

    assert {:ok, {~w/x/, ~w/y z/}} = ~w/x y z/ |> many(any([string("x")])).()
    assert {:ok, {~w/x y/, ~w/z/}} = ~w/x y z/ |> many(any([string("x"), string("y")])).()
    assert {:ok, {~w/x x x/, []}} = ~w/x x x/ |> many(any([string("x"), string("y"), string("z")])).()
    assert {:ok, {~w/x y z/, []}} = ~w/x y z/ |> many(any([string("x"), string("y"), string("z")])).()
    assert {:ok, {[], ~w/a/}} = ~w/a/ |> many(any([string("x"), string("y"), string("z")])).()
  end

  test "parses until" do
    assert {:ok, {~w/x/, ~w/y/}} = ~w/x y/ |> until(string("x"), string("y")).()
    assert {:ok, {~w/x/, ~w/y z/}} = ~w/x y z/ |> until(string("x"), string("y")).()
    assert {:ok, {~w/x x x/, ~w/y z/}} = ~w/x x x y z/ |> until(string("x"), string("y")).()
    assert {:ok, {[], ~w/y x/}} = ~w/y x/ |> until(string("x"), string("y")).()
    assert {:error, ~w/z y/, _} = ~w/x z y/ |> until(string("x"), string("y")).()
    assert {:error, ~w/z y/, _} = ~w/x x z y/ |> until(string("x"), string("y")).()

    parser = any([string("x"), string("y"), string("z")])
    assert {:ok, {~w/z z y x x y/, ~w/stop x/}} = ~w/z z y x x y stop x/ |> until(parser, string("stop")).()
    assert {:error, _} = ~w/z z y x x y invalid stop x/ |> until(parser, string("stop")).()
  end

  test "parses sequence" do
    [x, y, z] = [string("x"), string("y"), string("z")]
    assert {:ok, {~w/x/, ~w/y/}} = ~w/x y/ |> sequence([x]).()
    assert {:ok, {~w/x y/, []}} = ~w/x y/ |> sequence([x, y]).()
    assert {:ok, {~w/x x y/, []}} = ~w/x x y/ |> sequence([x, x, y]).()
    assert {:ok, {~w/x y/, ~w/z/}} = ~w/x y z/ |> sequence([x, y]).()
    assert {:ok, {~w/x y y y z/, []}} = ~w/x y y y z/ |> sequence([x, many(y), z]).()
    assert {:ok, {~w/x z/, []}} = ~w/x z/ |> sequence([x, many(y), z]).()
    assert {:error, ~w/a x y z/, _} = ~w/a x y z/ |> sequence([x, y, z]).()
    assert {:error, ~w/a y z/, _} = ~w/x a y z/ |> sequence([x, y, z]).()
    assert {:error, ~w/y x z/, _} = ~w/y x z/ |> sequence([x, y, z]).()
  end

  test "parses between" do
    [x, y, z] = [string("x"), string("y"), string("z")]
    parser = between(x, y, z)
    assert {:ok, {~w/y/, []}} = ~w/x y z/ |> parser.()
    assert {:ok, {~w/y/, ~w/a b/}} = ~w/x y z a b/ |> parser.()
    assert {:error, ~w/a x y z/, "x"} = ~w/a x y z/ |> parser.()
    assert {:error, ~w/y z/, "x"} = ~w/y z/ |> parser.()
    assert {:error, [], "z"} = ~w/x y/ |> parser.()
    assert {:error, ~w/a/, "z"} = ~w/x y a/ |> parser.()
    assert {:error, ~w/a z/, "z"} = ~w/x y a z/ |> parser.()

    parser = between(string("("), many(any([x, y, z])), string(")"))
    assert {:ok, {~w/x y z/, []}} = ~w/( x y z )/ |> parser.()
    assert {:ok, {~w/z z y/, ~w/a b/}} = ~w/( z z y ) a b/ |> parser.()
    assert {:error, ~w/x ( x y z )/, "("} = ~w/x ( x y z )/ |> parser.()
    assert {:error, ~w/x y z )/, "("} = ~w/x y z )/ |> parser.()
    assert {:error, [], _} = ~w/( x y z/ |> parser.()
    assert {:error, ~w/a/, _} = ~w/( x y a/ |> parser.()
    assert {:error, ~w/a )/, _} = ~w/( x y a )/ |> parser.()
  end

  test "parses EOF" do
    assert {:ok, {[], []}} = [] |> eof.()
    assert {:ok, {~w/x/, []}} = ~w/x/ |> both(string("x"), eof).()
    assert {:error, ~w/x/, []} = ~w/x/ |> eof.()
    assert {:error, ~w/y/, []} = ~w/x y/ |> both(string("x"), eof).()
  end

  test "throws error if required parser fails" do
    assert {:error, ~w/y/, "x"} = catch_throw(~w/y/ |> required(string("x")).())
  end

  test "describe parser overrides inner parser's expected value" do
    parser = string("x")
    assert {:error, ~w/y/, "x"} = parser.(["y"])
    assert {:error, ~w/y/, "looking for x!"} = ParserCombinators.describe(parser, "looking for x!").(["y"])
    assert {:error, [], :xxx} = ParserCombinators.describe(parser, :xxx).([])

    parser = any([string("a"), string("b"), string("c")])
    assert {:error, _} = parser.(["x"])
    assert {:error, ~w/x/, _} = ParserCombinators.describe(parser, "a, b, or c").(["x"])
  end

  test "transforms parsers" do
    to_upper = fn (res) -> Enum.map(res, &String.upcase&1) end
    assert {:ok, {~w/X/, []}} = ~w/x/ |> transform(to_upper, string("x")).()
    assert {:error, ~w/y x/, "x"} = ~w/y x/ |> transform(to_upper, string("x")).()
    assert {:ok, {~w/X X/, ~w/y/}} = ~w/x x y/ |> transform(to_upper, many(string("x"))).()

    duplicate = fn (res) -> Enum.flat_map(res, &[&1, &1]) end
    assert {:ok, {~w/x x/, ~w/y/}} = ~w/x y/ |> transform(duplicate, string("x")).()
    assert {:ok, {~w/X X X X/, []}} = ~w/x x/ |> transform(to_upper, transform(duplicate, many(string("x")))).()
  end

  test "wraps parsers into nested lists" do
    assert {:ok, {[["x"]], []}} = ~w/x/ |> wrap(string("x")).()

    parser = many(any([string("x"), wrap(string("y"))]))
    assert {:ok, {["x", ["y"], "x", ["y"], ["y"]], []}} = ~w/x y x y y/ |> parser.()
  end

  test "handles ambiguity in optional parsers" do
    # parser = either(
    #   # if X then
    #   # if X then Y else Z
    #   sequence([string("x"), both(string("y"), string("z"))]),
    #   sequence([both(string("x"), string("y")), string("z")])
    # )
    # Elixir can't handle self-refential anonymous functions so we have to pass the function itself as an argument:
    parser = fn (self) -> any([
      sequence([string("if"), string("..."), self]),
      sequence([string("if"), string("..."), self, string("else"), self]),
      string("x=10")
    ]) end

    assert {:ok, {~w/x y z/, []}} = ~w/if ... if ... x=10 else x=10/ |> parser.(parser).()
  end
end
