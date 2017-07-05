defmodule Sammal.Eval do
  @moduledoc """
  Evaluate parsed Lisp expressions.
  """
  alias Sammal.{Env, Expr, Parser, SammalError}


  @spec eval_all([Parser.form], Env) :: {any, Env}
  def eval_all([], env), do: {nil, env}
  def eval_all([exp], env), do: eval(exp, env)
  def eval_all([exp | rest], env) do
    {result, new_env} = eval(exp, env)
    eval_all(rest, new_env)
  end

  def eval_all(_), do: throw "Expecting a list of expressions" # TODO handle

  # TODO also include context here? for errors etc

  @doc """
  Evaluate a single expression or a form in given environment.
  """
  @spec eval(Parser.form | Expr, Env) :: {any, Env}
  def eval(%Expr{val: []}, env), do: {[], env}
  def eval(%Expr{val: val} = expr, env) when is_atom(val) do
    case Env.lookup_var(env, val) do
      {:ok, res} -> {res, env}
      {:error, _} -> throw SammalError.new(:unbound, expr)
    end
  end

  def eval(%Expr{val: val}, env) when is_number(val) or is_binary(val) or is_boolean(val) do
    {val, env}
  end

  def eval([%Expr{val: :define} = head, %Expr{val: var}, %Expr{} = val], env) when is_atom(var) do
    unless Env.top_level?(env) do
      # TODO allow internal definitions http://schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-8.html#%25_sec_5.2.2
      throw SammalError.new(:cannot_bind, head)
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
  def eval([%Expr{val: val} = head | rest], env) when is_atom(val) do
    {proc, _} = eval(head, env)
    proc_scope = %Env{parent: env}
    args = Enum.map(rest, fn arg -> eval(arg, proc_scope) |> elem(0) end)
    {proc.(args), env}
  end

  def eval([%Expr{} = expr | _], _), do: throw SammalError.new(:not_applicable, expr)

  # TODO remove
  def eval_raw(raw_code) do
    {:ok, tokens} = Sammal.Tokenizer.tokenize(raw_code)
    {:ok, {ast, _}} = Sammal.Parser.parse(tokens)
    unless Mix.env == :test do
      IO.inspect ast, label: "Evaluating AST"
    end
    eval_all(ast, Env.global)
  end
end

