defmodule Sammal do
  @moduledoc """
  Sammal main module.
  """

  import Sammal.{Tokenizer, Parser}

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
    with {tokens, []} <- tokenize(input),
         {parse_tree, [], []} <- parse_expression(tokens) do
      IO.inspect parse_tree, pretty: true # TODO evaluate here
    else
      {_, errors} ->
        show_failure(errors, "Token error on command")
      {_, _, errors} ->
        show_failure(errors, "Parsing error on command")
    end
  end

  def show_failure(errors, header \\ "Syntax error") do
    IO.puts """
    == #{header} ==
    #{Enum.map(errors, &("\n" <> to_string(&1)))}
    """
  end
end
