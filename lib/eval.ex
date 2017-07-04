defmodule Sammal.Eval do
  @moduledoc """
  Evaluate parsed Lisp expressions.
  """
  alias Sammal.{Env, SammalError}


  @type expression :: [any]

  @spec eval_all([expression], Sammal.Env) :: {any, Sammal.Env}
  def eval_all([], env), do: {nil, env}
  def eval_all([exp], env) when is_list(exp), do: eval(exp, env)
  def eval_all([exp | rest], env) when is_list(exp) do
    {result, new_env} = eval(exp, env)
    eval_all(rest, new_env)
  end

  def eval_all(_), do: {:error, "Expecting a list of expressions"} # TODO handle

  # TODO also include context here? for errors etc

  @doc """
  Evaluate a single expression in given environment.
  """
  @spec eval(any, Sammal.Env) :: {any, Sammal.Env}
  def eval(val, env) when is_atom(val) do
    case Env.lookup_var(env, val) do
      {:ok, res} -> {res, env}
      {:error, _} -> throw "unexpected variable" # TODO handle
    end
  end

  def eval(val, env) when is_number(val) or is_binary(val) or is_boolean(val) do
    {val, env}
  end

  def eval([:define, var, val], env) when is_atom(var) do
    unless Env.top_level?(env) do
      # TODO allow internal definitions http://schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-8.html#%25_sec_5.2.2
      throw "Top-level required"
    end

    {resolved_val, _} = eval(val, env)
    {:ok, new_env} = Env.assign(env, var, resolved_val)
    {nil, new_env}
  end

  # TODO:
  # def eval([:let, ...
  # def eval([:lambda, ...
  # TODO lookup and handle macros

  # procedure call:
  def eval([t | ts], env) when is_atom(t) do
    {func, _} = eval(t, env)
    args = Enum.map(ts, fn arg -> eval(arg, env) |> elem(0) end)
    {func.(args), env}
  end

  # TODO remove
  def eval_raw(raw_code) do
    {:ok, tokens} = Sammal.Tokenizer.tokenize(raw_code)
    {:ok, {ast, _}} = Sammal.Parser.parse(tokens)
    IO.inspect ast, label: "Evaluating AST"
    eval_all(ast, Env.global)
  end
end

