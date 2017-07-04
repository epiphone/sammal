defmodule Sammal.EnvTest do
  use ExUnit.Case, async: true
  doctest Sammal.Env

  import Sammal.Env
  alias Sammal.Env


  test "differentiates between global/local scopes" do
    assert global().parent == nil
    assert top_level?(global) == true
    assert top_level?(%Env{parent: global}) == false
  end

  test "assigns and looks up variables" do
    assert {:error, _} = lookup_var(global, :x)
    assert {:ok, env} = assign(global, :x, 10)
    assert {:ok, 10} = lookup_var(env, :x)

    local_env = %Env{parent: env}
    assert not :x in local_env.vars
    assert {:ok, 10} =  lookup_var(local_env, :x)
    assert {:ok, local_env} = assign(local_env, :x, 11)
    assert {:ok, 10} =  lookup_var(local_env.parent, :x)
    assert {:ok, 11} =  lookup_var(local_env, :x)
  end
end
