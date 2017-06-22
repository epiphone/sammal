defmodule Sammal.Env do
  @moduledoc """
  Sammal evaluation environment.
  """

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
    %{list: &List.wrap/1,
      +: &Enum.sum/1,
      -: &subtract/1,
      *: &product/1,
      /: &division/1,
    }
  end
end
