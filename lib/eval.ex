defmodule Sammal.Eval do
  @moduledoc """
  Evaluate parsed Lisp expressions.
  """
  alias Sammal.{Env, SammalError}

  # TODO also include context here? for errors etc

  def eval(val, env) when is_atom(val) do
    case lookup_env(env, val) do
      nil -> throw "TODO unexpected variable" # TODO how to handle null?
      res -> res
    end
  end

  def eval(val, env) when is_number(val) or is_binary(val) or is_binary(val) do
    val
  end

  def eval([t | ts], env) do
    func = eval(t, env)
    args = Enum.map(ts, &eval(&1, env))
    func.(args)
  end

  def lookup_env(env, key) do
    Map.get(env, key)
  end

  # TODO remove
  def test(raw_code) do
    {:ok, tokens} = Sammal.Tokenizer.tokenize(raw_code)
    {:ok, {[ast], _}} = Sammal.Parser.parse(tokens)
    IO.inspect ast
    eval(ast, Env.global)
  end
end

