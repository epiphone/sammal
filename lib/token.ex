defmodule Sammal.Token do
  @enforce_keys [:lexeme]
  defstruct [:lexeme, :line, :index, :value]
end
