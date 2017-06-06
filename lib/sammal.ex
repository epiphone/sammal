defmodule Sammal do
  @moduledoc """
  Sammal main module.
  """
  import Sammal.Parser, only: [parse: 1]
  import Sammal.Tokenizer, only: [tokenize: 1]

  @doc """
  Program entry point.
  """
  def main(args) do
    options = OptionParser.parse(args, strict: [command: :string, interactive: :boolean],
                                       aliases: [c: :command, i: :interactive])
    case options do
      {[], [path], _} ->
        IO.puts "TODO implement handling source files"
      {[command: command], _, _} ->
        run_command(command)
      {[interactive: true], _, _} ->
        IO.puts "TODO implement REPL"
      _ ->
        IO.puts """
        Sammal usage:

        ## Evaluate a source file:
        > sammal main.sammal

        ## Directly evaluate a command:
        > sammal -c "(define x 10)"

        ## Run the interactive REPL:
        > sammal -i
        """
    end
  end

  def run_command(input) do
    with {:ok, tokens} <- tokenize(input),
         {:ok, {ast, []}} <- parse(tokens) do
      IO.inspect ast, pretty: true # TODO evaluate here
    else
      {:error, %Sammal.SammalError{message: message}} ->
        IO.puts message
    end
  end

  def show_failure(errors, header \\ "Syntax error") do
    IO.puts """
    == #{header} ==
    #{Enum.map(errors, &("\n" <> to_string(&1)))}
    """
  end
end
