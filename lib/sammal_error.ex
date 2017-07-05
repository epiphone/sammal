defmodule Sammal.SammalError do
  @moduledoc """
  An error struct and helpers for generating error messages with context.
  """
  defstruct [:expected, :message, :expr, :type]

  @doc """
  Construct an error struct.
  """
  def new(type, %Sammal.Expr{} = expr, expected \\ nil) do
    expr_str = "'#{expr.lex}' at #{expr.line}:#{expr.row}"
    message =
      case type do
        :ending_quote -> "Missing ending quote for #{expr_str}"
        :unexpected_token -> "Unexpected expr #{expr_str} - expecting '#{expected}'"
        :unmatched_paren -> "Unmatched open parenthesis #{expr_str}"
        _ -> "Invalid expr #{expr_str}"
      end

    %__MODULE__{expected: expected, message: message, expr: expr, type: type}
  end
end
