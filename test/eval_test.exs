defmodule Sammal.EvalTest do
  use ExUnit.Case, async: true
  doctest Sammal.Eval

  import Sammal.Eval


  test "defines variables" do
    assert {nil, %{x: 10}} = "(define x 10)" |> ast |> eval
  end

  defp ast(raw_code) do
    {:ok, tokens} = Sammal.Tokenizer.tokenize(raw_code)
    {:ok, {[ast], _}} = Sammal.Parser.parse(tokens)
    ast
  end
end
