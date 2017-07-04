defmodule Sammal.EvalTest do
  use ExUnit.Case, async: true
  doctest Sammal.Eval

  import Sammal.Eval
  alias Sammal.Env


  test "defines variables" do
    assert {nil, %Env{vars: %{x: 10}}} = "(define x 10)" |> eval_raw
  end

  test "returns the result of last expression" do
    assert {10, _} = "(define x 9) (- 1 2) (+ x 1)" |> eval_raw
    assert {nil, _} = "(+ 2 1) (define x 10)" |> eval_raw
  end
end
