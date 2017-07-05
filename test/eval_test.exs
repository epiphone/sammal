defmodule Sammal.EvalTest do
  use ExUnit.Case, async: true
  doctest Sammal.Eval

  import Sammal.Eval
  alias Sammal.{Env, SammalError}


  test "defines variables" do
    assert {nil, %Env{vars: %{x: 10}}} = "(define x 10)" |> eval_raw
  end

  test "evaluate non-compound expressions" do
    assert {"asd", _} = "\"asd\"" |> eval_raw
    assert {4, _} = "\"asd\" (define x 1) (+ x 2) 4" |> eval_raw
    assert {2, _} = "+ 1 2" |> eval_raw
    assert {[], _} = "()" |> eval_raw
  end

  test "returns the result of last expression" do
    assert {10, _} = "(define x 9) (- 1 2) (+ x 1)" |> eval_raw
    assert {1, _} = "(define x 1) x" |> eval_raw
    assert {nil, _} = "(+ 2 1) (define x 10)" |> eval_raw
  end

  test "throws error when trying to call a non-applicable expression" do
    assert_throw :not_applicable, "(10)"
    assert_throw :not_applicable, "(10 12)"
    assert_throw :not_applicable, "(+ 10 (12))"
    assert_throw :not_applicable, "(\"some string\")"
    assert_throw :not_applicable, "(10.2)"
    assert_throw :not_applicable, "(())"
  end

  test "throws error when referring to unbound variables" do
    assert_throw :unbound, "(x)"
    assert_throw :unbound, "(define x 10) (+ x y)"
  end

  test "throws error when defining globals in local scope" do
    assert_throw :cannot_bind, "(+ (define x 10) 12)"
  end

  defp assert_throw(type, raw_expression) do
    assert %SammalError{type: type} = catch_throw(raw_expression |> eval_raw)
  end
end
