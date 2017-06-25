defmodule Sammal.Eval do
  @moduledoc """
  Evaluate parsed Lisp expressions.
  """
  alias Sammal.{Env, SammalError}

  # TODO also include context here? for errors etc

  @doc """
  Evaluate a single token in given environment.
  """
  @spec eval(any, map) :: {any, map}
  def eval(val, env \\ %{})

  def eval(val, env) when is_atom(val) do
    case lookup_env(env, val) do
      nil -> throw "TODO unexpected variable" # TODO how to handle null?
      res -> {res, env}
    end
  end

  def eval(val, env) when is_number(val) or is_binary(val) or is_binary(val) do
    {val, env}
  end

  # TODO disable define in inner scope
  def eval([:define, var, val], env) when is_atom(var) do
    {bound, _} = eval(val, env)
    {nil, Map.put(env, var, bound)}
  end

  # function call:
  def eval([t | ts], env) do
    {func, _} = eval(t, env)
    args = Enum.map(ts, &elem(eval(&1, env), 0))
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

