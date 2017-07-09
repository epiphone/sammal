defmodule Sammal.Expr do
  @moduledoc """
  A Scheme expression with contextual information.
  """
  defstruct [:ctx, :lex, :line, :row, :val]
end
