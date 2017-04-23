defmodule Sammal.SammalError do
  defstruct [:type, :token, :expected]
end

defimpl String.Chars, for: Sammal.SammalError do
  def to_string(%{expected: exp, token: t, type: :unexpected_token}) do
    "Unexpected token '#{t.lexeme}' at #{t.line}:#{t.index} - expecting '#{exp}'"
  end

  def to_string(%{token: t, type: :ending_quote}) do
    "Missing ending quote for '#{t.lexeme}' at #{t.line}:#{t.index}"
  end
end

