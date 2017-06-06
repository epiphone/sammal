defmodule Sammal.SammalError do
  @moduledoc """
  An error struct and helpers for generating error messages with context.
  """
  defstruct [:expected, :message, :token, :type]

  @doc """
  Construct an error struct.
  """
  def new(type, %Sammal.Token{} = token, expected \\ nil) do
    token_str = "'#{token.lexeme}' at #{token.line}:#{token.index}"
    message =
      case type do
        :ending_quote -> "Missing ending quote for #{token_str}"
        :unexpected_token -> "Unexpected token #{token_str} - expecting '#{expected}'"
        :unmatched_paren -> "Unmatched open parenthesis #{token_str}"
        _ -> "Invalid token #{token_str}"
      end

    %__MODULE__{expected: expected, message: message, token: token, type: type}
  end
end
