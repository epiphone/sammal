defmodule Sammal.Env do
  @moduledoc """
  Sammal evaluation environment.
  """
  defstruct parent: nil, vars: %{}, macros: %{}

  # Handle basic arithmetic operators as outlined in the Scheme spec:
  # https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Numerical-operations.html
  def subtract([]), do: 0
  def subtract([x]), do: -x
  def subtract(xs), do: Enum.reduce(xs, &(&2 - &1))

  def product([]), do: 1
  def product([x|xs]), do: x * product(xs)

  def division([]), do: 1
  def division([x]), do: 1 / x
  def division(xs), do: Enum.reduce(xs, &(&2 / &1))

  def global do
    %__MODULE__{
      parent: nil,
      vars: %{
        list: &List.wrap/1,
        +: &Enum.sum/1,
        -: &subtract/1,
        *: &product/1,
        /: &division/1
      },
      macros: %{}
    }
  end

  @doc """
  Assign variable into given environment.
  """
  def assign(%__MODULE__{vars: vars} = env, var, val) when is_atom(var) do
    {:ok, %{env | vars: Map.put(vars, var, val)}}
  end

  @doc """
  Look up variable first from local scope, then from parent scopes.
  """
  def lookup_var(nil, _), do: {:error, nil}
  def lookup_var(%__MODULE__{parent: parent, vars: vars}, var) when is_atom(var) do
    if Map.has_key?(vars, var) do
      {:ok, vars[var]}
    else
      lookup_var(parent, var)
    end
  end

  @doc """
  Return true if given env is the top-level (or global) scope.

  Some operations (e.g. `define`) are only valid in the top-level scope.
  """
  def top_level?(%__MODULE__{parent: parent}), do: is_nil(parent)
end
