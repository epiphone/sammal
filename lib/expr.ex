defmodule Sammal.Expr do
  @moduledoc """
  A Scheme expression with contextual information.
  """
  @enforce_keys [:lex]
  defstruct [:ctx, :lex, :line, :row, :val]
end
